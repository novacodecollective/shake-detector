// Copyright © 2014-2019 the Surge contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Accelerate

// MARK: - Fast Fourier Transform

func fft(_ input: [Double]) -> [Double] {
    var real = [Double](input)
    var imaginary = [Double](repeating: 0.0, count: input.count)
    var splitComplex = DSPDoubleSplitComplex(realp: &real, imagp: &imaginary)

    let length = vDSP_Length(floor(log2(Float(input.count))))
    let radix = FFTRadix(kFFTRadix2)
    let weights = vDSP_create_fftsetupD(length, radix)
    withUnsafeMutablePointer(to: &splitComplex) { splitComplex in
        vDSP_fft_zipD(weights!, splitComplex, 1, length, FFTDirection(FFT_FORWARD))
    }

    var magnitudes = [Double](repeating: 0.0, count: input.count)
    withUnsafePointer(to: &splitComplex) { splitComplex in
        magnitudes.withUnsafeMutableBufferPointer { magnitudes in
            vDSP_zvmagsD(splitComplex, 1, magnitudes.baseAddress!, 1, vDSP_Length(input.count))
        }
    }

    var normalizedMagnitudes = [Double](repeating: 0.0, count: input.count)
    normalizedMagnitudes.withUnsafeMutableBufferPointer { normalizedMagnitudes in
        vDSP_vsmulD(sqrt(magnitudes), 1, [2.0 / Double(input.count)], normalizedMagnitudes.baseAddress!, 1, vDSP_Length(input.count))
    }

    vDSP_destroy_fftsetupD(weights)

    return normalizedMagnitudes
}

@inline(__always)
func withArray<T, S>(from sequence: S, _ closure: (inout [T]) -> ()) -> [T] where S: Sequence, S.Element == T {
    var array = Array(sequence)
    closure(&array)
    return array
}

/// Elemen-wise square root.
///
/// - Warning: does not support memory stride (assumes stride is 1).
func sqrt<L>(_ lhs: L) -> [Double] where L: UnsafeMemoryAccessible, L.Element == Double {
    return withArray(from: lhs) { sqrtInPlace(&$0) }
}

/// Elemen-wise square root with custom output storage.
///
/// - Warning: does not support memory stride (assumes stride is 1).
func sqrt<MI: UnsafeMemoryAccessible, MO>(_ lhs: MI, into results: inout MO) where MO: UnsafeMutableMemoryAccessible, MI.Element == Double, MO.Element == Double {
    return lhs.withUnsafeMemory { lm in
        results.withUnsafeMutableMemory { rm in
            precondition(lm.stride == 1 && rm.stride == 1, "sqrt doesn't support step values other than 1")
            precondition(rm.count >= lm.count, "`results` doesnt have enough capacity to store the results")
            vvsqrt(rm.pointer, lm.pointer, [numericCast(lm.count)])
        }
    }
}

// MARK: - Square Root: In Place
/// Elemen-wise square root.
///
/// - Warning: does not support memory stride (assumes stride is 1).
func sqrtInPlace<L>(_ lhs: inout L) where L: UnsafeMutableMemoryAccessible, L.Element == Double {
    var elementCount: Int32 = numericCast(lhs.count)
    lhs.withUnsafeMutableMemory { lm in
        precondition(lm.stride == 1, "\(#function) doesn't support step values other than 1")
        vvsqrt(lm.pointer, lm.pointer, &elementCount)
    }
}

/// Memory region.
struct UnsafeMemory<Element>: Sequence {
    /// Pointer to the first element
    var pointer: UnsafePointer<Element>

    /// Pointer stride between elements
    var stride: Int

    /// Number of elements
    var count: Int

    init(pointer: UnsafePointer<Element>, stride: Int = 1, count: Int) {
        self.pointer = pointer
        self.stride = stride
        self.count = count
    }

    func makeIterator() -> UnsafeMemoryIterator<Element> {
        return UnsafeMemoryIterator(self)
    }
}

struct UnsafeMemoryIterator<Element>: IteratorProtocol {
    let base: UnsafeMemory<Element>
    var index: Int?

    init(_ base: UnsafeMemory<Element>) {
        self.base = base
    }

    mutating func next() -> Element? {
        let newIndex: Int
        if let index = index {
            newIndex = index + 1
        } else {
            newIndex = 0
        }

        if newIndex >= base.count {
            return nil
        }

        self.index = newIndex
        return base.pointer[newIndex * base.stride]
    }
}

/// Protocol for collections that can be accessed via `UnsafeMemory`
protocol UnsafeMemoryAccessible: Collection {
    func withUnsafeMemory<Result>(_ body: (UnsafeMemory<Element>) throws -> Result) rethrows -> Result
}

func withUnsafeMemory<L, Result>(_ lhs: L, _ body: (UnsafeMemory<L.Element>) throws -> Result) rethrows -> Result where L: UnsafeMemoryAccessible {
    return try lhs.withUnsafeMemory(body)
}

func withUnsafeMemory<L, R, Result>(_ lhs: L, _ rhs: R, _ body: (UnsafeMemory<L.Element>, UnsafeMemory<R.Element>) throws -> Result) rethrows -> Result where L: UnsafeMemoryAccessible, R: UnsafeMemoryAccessible {
    return try lhs.withUnsafeMemory { lhsMemory in
        try rhs.withUnsafeMemory { rhsMemory in
            try body(lhsMemory, rhsMemory)
        }
    }
}

/// Mutable memory region.
struct UnsafeMutableMemory<Element> {
    /// Pointer to the first element
    var pointer: UnsafeMutablePointer<Element>

    /// Pointer stride between elements
    var stride: Int

    /// Number of elements
    var count: Int

    init(pointer: UnsafeMutablePointer<Element>, stride: Int = 1, count: Int) {
        self.pointer = pointer
        self.stride = stride
        self.count = count
    }

    func makeIterator() -> UnsafeMutableMemoryIterator<Element> {
        return UnsafeMutableMemoryIterator(self)
    }
}

struct UnsafeMutableMemoryIterator<Element>: IteratorProtocol {
    let base: UnsafeMutableMemory<Element>
    var index: Int?

    init(_ base: UnsafeMutableMemory<Element>) {
        self.base = base
    }

    mutating func next() -> Element? {
        let newIndex: Int
        if let index = index {
            newIndex = index + 1
        } else {
            newIndex = 0
        }

        if newIndex >= base.count {
            return nil
        }

        self.index = newIndex
        return base.pointer[newIndex * base.stride]
    }
}

/// Protocol for mutable collections that can be accessed via `UnsafeMutableMemory`
protocol UnsafeMutableMemoryAccessible: UnsafeMemoryAccessible {
    mutating func withUnsafeMutableMemory<Result>(_ body: (UnsafeMutableMemory<Element>) throws -> Result) rethrows -> Result
}

func withUnsafeMutableMemory<L, Result>(_ lhs: inout L, _ body: (UnsafeMutableMemory<L.Element>) throws -> Result) rethrows -> Result where L: UnsafeMutableMemoryAccessible {
    return try lhs.withUnsafeMutableMemory(body)
}

func withUnsafeMutableMemory<L, R, Result>(_ lhs: inout L, _ rhs: inout R, _ body: (UnsafeMutableMemory<L.Element>, UnsafeMutableMemory<R.Element>) throws -> Result) rethrows -> Result where L: UnsafeMutableMemoryAccessible, R: UnsafeMutableMemoryAccessible {
    return try lhs.withUnsafeMutableMemory { lhsMemory in
        try rhs.withUnsafeMutableMemory { rhsMemory in
            try body(lhsMemory, rhsMemory)
        }
    }
}

func withUnsafeMutableMemory<L, R, Z, Result>(_ lhs: inout L, _ rhs: inout R, _ z: inout Z, _ body: (UnsafeMutableMemory<L.Element>, UnsafeMutableMemory<R.Element>, UnsafeMutableMemory<Z.Element>) throws -> Result) rethrows -> Result where L: UnsafeMutableMemoryAccessible, R: UnsafeMutableMemoryAccessible, Z: UnsafeMutableMemoryAccessible {
    return try lhs.withUnsafeMutableMemory { lhsMemory in
        try rhs.withUnsafeMutableMemory { rhsMemory in
            try z.withUnsafeMutableMemory { zm in
                try body(lhsMemory, rhsMemory, zm)
            }
        }
    }
}

extension Array: UnsafeMemoryAccessible, UnsafeMutableMemoryAccessible {
    func withUnsafeMemory<Result>(_ action: (UnsafeMemory<Element>) throws -> Result) rethrows -> Result {
        return try withUnsafeBufferPointer { ptr in
            guard let base = ptr.baseAddress else {
                fatalError("Array is missing its pointer")
            }
            let memory = UnsafeMemory(pointer: base, stride: 1, count: ptr.count)
            return try action(memory)
        }
    }

    mutating func withUnsafeMutableMemory<Result>(_ action: (UnsafeMutableMemory<Element>) throws -> Result) rethrows -> Result {
        return try withUnsafeMutableBufferPointer { ptr in
            guard let base = ptr.baseAddress else {
                fatalError("Array is missing its pointer")
            }
            let memory = UnsafeMutableMemory(pointer: base, stride: 1, count: ptr.count)
            return try action(memory)
        }
    }
}
