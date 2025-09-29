import Foundation


// Errors
enum CaesarError: Error, CustomStringConvertible {
    case invalidLetters(found: String)
    case invalidShift
    case invalidKeyword(reason: String)

    var description: String {
        switch self {
        case .invalidLetters(let found):
            return "The text/key contains invalid symbols: \"\(found)\". Only letters A–Z are allowed."
        case .invalidShift:
            return "The numeric key must be in the range 1…25."
        case .invalidKeyword(let reason):
            return "Key 2 (keyword) is invalid: \(reason)"
        }
    }
}


let ALPHABET: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
let LOWER:    [Character] = Array("abcdefghijklmnopqrstuvwxyz")

// Index of uppercase A–Z (top row 0…25)
let INDEX_IN_A: [Character: Int] = {
    var d: [Character:Int] = [:]
    for (i, c) in ALPHABET.enumerated() { d[c] = i }
    return d
}()

// Lowercase → Uppercase mapping
let LOWER_TO_UPPER: [Character: Character] = {
    var m: [Character:Character] = [:]
    for i in 0..<26 { m[LOWER[i]] = ALPHABET[i] }
    return m
}()

@inline(__always)
func mod26(_ x: Int) -> Int { ((x % 26) + 26) % 26 }

// Convert a single character to uppercase A–Z using the tables.
// Returns nil if the char is not a letter A–Z/a–z.
@inline(__always)
func toUpperAZ(_ ch: Character) -> Character? {
    if let up = LOWER_TO_UPPER[ch] { return up } // was lowercase a–z
    if INDEX_IN_A[ch] != nil { return ch }       // already uppercase A–Z
    return nil
}

// Remove spaces, ensure letters only, convert to uppercase via manual tables.
func sanitizeMessage(_ s: String) throws -> String {
    var out: [Character] = []
    out.reserveCapacity(s.count)
    var bad: [Character] = []

    for ch in s {
        if ch == " " { continue }
        if let up = toUpperAZ(ch) {
            out.append(up)
        } else {
            bad.append(ch)
        }
    }
    if !bad.isEmpty { throw CaesarError.invalidLetters(found: String(bad)) }
    return String(out)
}

// Keyword: letters only, length >= 7, uppercase via manual mapping
func sanitizeKeyword(_ s: String) throws -> String {
    var out: [Character] = []
    out.reserveCapacity(s.count)
    var bad: [Character] = []

    for ch in s {
        if ch == " " { continue }
        if let up = toUpperAZ(ch) {
            out.append(up)
        } else {
            bad.append(ch)
        }
    }
    if !bad.isEmpty { throw CaesarError.invalidLetters(found: String(bad)) }
    if out.count < 7 { throw CaesarError.invalidKeyword(reason: "length must be ≥ 7.") }
    return String(out)
}

// ============================================================
// Task 1.1 — Classic Caesar
// ============================================================

struct Caesar {
    static func encrypt(_ plain: String, shift k: Int) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let p = try sanitizeMessage(plain)          // uppercase A–Z only, no spaces
        var out = ""
        out.reserveCapacity(p.count)

        for ch in p {
           
            guard let idx = INDEX_IN_A[ch] else {
                throw CaesarError.invalidLetters(found: String(ch))
            }
            let e = mod26(idx + k)                  // move down k positions in the table
            out.append(ALPHABET[e])                 // take from shifted row
        }
        return out
    }

    static func decrypt(_ cipher: String, shift k: Int) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let c = try sanitizeMessage(cipher)
        var out = ""
        out.reserveCapacity(c.count)

        for ch in c {
            guard let idx = INDEX_IN_A[ch] else {
                throw CaesarError.invalidLetters(found: String(ch))
            }
            let d = mod26(idx - k)                  // move up k positions in the table
            out.append(ALPHABET[d])
        }
        return out
    }
}

// ============================================================
// Task 1.2 — Caesar + Permutation

// ============================================================

struct CaesarWithPermutation {

    // Build the keyword-based permuted alphabet P
    static func keywordAlphabet(_ keyword: String) throws -> [Character] {
        let k = try sanitizeKeyword(keyword)
        var seen = Set<Character>()
        var P: [Character] = []

        // Unique letters of the keyword in order
        for ch in k {
            if !seen.contains(ch) {
                seen.insert(ch)
                P.append(ch)
            }
        }
        // Then the remaining letters of A in natural order
        for ch in ALPHABET where !seen.contains(ch) {
            seen.insert(ch)
            P.append(ch)
        }
        // P is the second row in the 1.2 table
        return P
    }

    // Encrypt: E(x) = P[(index_P(x) + k) mod 26]
    static func encrypt(_ plain: String, shift k: Int, keyword: String) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let p = try sanitizeMessage(plain)
        let P = try keywordAlphabet(keyword)

        // Index in P (like top-row indexes for 1.1, but over P now)
        var posInP: [Character:Int] = [:]
        for (i, ch) in P.enumerated() { posInP[ch] = i }

        var out = ""
        out.reserveCapacity(p.count)
        for ch in p {
            guard let i = posInP[ch] else {
                throw CaesarError.invalidLetters(found: String(ch))
            }
            out.append(P[mod26(i + k)])             // shift inside P
        }
        return out
    }

    // Decrypt: D(y) = P[(index_P(y) - k) mod 26]
    static func decrypt(_ cipher: String, shift k: Int, keyword: String) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let c = try sanitizeMessage(cipher)
        let P = try keywordAlphabet(keyword)

        var posInP: [Character:Int] = [:]
        for (i, ch) in P.enumerated() { posInP[ch] = i }

        var out = ""
        out.reserveCapacity(c.count)
        for ch in c {
            guard let j = posInP[ch] else {
                throw CaesarError.invalidLetters(found: String(ch))
            }
            out.append(P[mod26(j - k)])             // inverse shift inside P
        }
        return out
    }
}

// ============================================================
// Console demo 
// ============================================================

func prompt(_ text: String) -> String {
    print(text, terminator: " ")
    return readLine() ?? ""
}

func menu() {
    print("""
    =================================================================
    Caesar Lab – 1.1 & 1.2
    Only letters A–Z are accepted. Spaces are removed; everything is uppercased.
    -------------------------
    1) Encrypt (Task 1.1 – classic Caesar)
    2) Decrypt (Task 1.1 – classic Caesar)
    3) Encrypt (Task 1.2 – Caesar + permutation)
    4) Decrypt (Task 1.2 – Caesar + permutation)
    0) Exit
    =================================================================
    """)
}

while true {
    menu()
    let choice = prompt("Choose an option:")
    if choice == "0" { break }

    do {
        switch choice {
        case "1":
            let msg = prompt("Message (letters only, spaces will be removed):")
            let k = Int(prompt("Numeric key (1…25):")) ?? -1
            let c = try Caesar.encrypt(msg, shift: k)
            print("Ciphertext:", c, "\n")
        case "2":
            let cip = prompt("Ciphertext:")
            let k = Int(prompt("Numeric key (1…25):")) ?? -1
            let m = try Caesar.decrypt(cip, shift: k)
            print("Decrypted message:", m, "\n")
        case "3":
            let msg = prompt("Message (letters only, spaces will be removed):")
            let k = Int(prompt("Numeric key (1…25):")) ?? -1
            let kw = prompt("Key 2 (keyword, letters A–Z, length ≥ 7):")
            let c = try CaesarWithPermutation.encrypt(msg, shift: k, keyword: kw)
            print("Ciphertext:", c, "\n")
        case "4":
            let cip = prompt("Ciphertext:")
            let k = Int(prompt("Numeric key (1…25):")) ?? -1
            let kw = prompt("Key 2 (keyword, letters A–Z, length ≥ 7):")
            let m = try CaesarWithPermutation.decrypt(cip, shift: k, keyword: kw)
            print("Decrypted message:", m, "\n")
        default:
            print("Unknown option.\n")
        }
    } catch {
        print("Error:", error, "\n")
    }
}
