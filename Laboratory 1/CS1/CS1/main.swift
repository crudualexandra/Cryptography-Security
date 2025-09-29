import Foundation

// MARK: - Utilities

enum CaesarError: Error, CustomStringConvertible {
    case invalidLetters(found: String)
    case invalidShift
    case invalidKeyword(reason: String)

    var description: String {
        switch self {
        case .invalidLetters(let found):
            return "Textul/cheia conține simboluri nepermise: \"\(found)\". Se admit doar litere A–Z."
        case .invalidShift:
            return "Cheia numerică trebuie să fie în intervalul 1…25."
        case .invalidKeyword(let reason):
            return "Cheia 2 (cuvânt cheie) este invalidă: \(reason)"
        }
    }
}

/// Keep only A–Z, make uppercase. If anything else appears, throw.
func sanitizeLettersOnly(_ s: String) throws -> String {
    let upper = s.uppercased()
    let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    let bad = upper.unicodeScalars.filter { !allowed.contains($0) }
    if !bad.isEmpty {
        let badAsString = String(String.UnicodeScalarView(bad))
        throw CaesarError.invalidLetters(found: badAsString)
    }
    return upper
}

/// Same as above, but drops spaces before validating.
func sanitizeMessage(_ s: String) throws -> String {
    let noSpaces = s.replacingOccurrences(of: " ", with: "")
    return try sanitizeLettersOnly(noSpaces)
}

let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

@inline(__always)
func mod26(_ x: Int) -> Int { ((x % 26) + 26) % 26 }

// MARK: - Task 1.1: Classic Caesar (A–Z, shift 1…25)

struct Caesar {
    static func encrypt(_ plain: String, shift k: Int) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let p = try sanitizeMessage(plain)
        var out = ""
        out.reserveCapacity(p.count)
        for ch in p {
            let idx = Int(ch.unicodeScalars.first!.value) - 65 // 'A' = 65
            let e = mod26(idx + k)
            out.append(alphabet[e])
        }
        return out
    }

    static func decrypt(_ cipher: String, shift k: Int) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let c = try sanitizeMessage(cipher)
        var out = ""
        out.reserveCapacity(c.count)
        for ch in c {
            let idx = Int(ch.unicodeScalars.first!.value) - 65
            let d = mod26(idx - k)
            out.append(alphabet[d])
        }
        return out
    }
}

// MARK: - Task 1.2: Caesar with permutation (two keys)

// shift INSIDE the permuted alphabet P
struct CaesarWithPermutation {
    static func keywordAlphabet(_ keyword: String) throws -> [Character] {
        let k = try sanitizeLettersOnly(keyword)           // uppercase, A–Z only
        guard k.count >= 7 else { throw CaesarError.invalidKeyword(reason: "lungimea trebuie să fie ≥ 7.") }
        var seen = Set<Character>(); var mixed: [Character] = []
        for ch in k { if !seen.contains(ch) { seen.insert(ch); mixed.append(ch) } }
        for ch in alphabet where !seen.contains(ch) { seen.insert(ch); mixed.append(ch) }
        return mixed
    }

    static func encrypt(_ plain: String, shift k: Int, keyword: String) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let p = try sanitizeMessage(plain)            // remove spaces, uppercase, A–Z only
        let P = try keywordAlphabet(keyword)
        var posInP: [Character:Int] = [:]
        for (i,ch) in P.enumerated() { posInP[ch] = i }
        var out = ""
        for ch in p {
            guard let i = posInP[ch] else { throw CaesarError.invalidLetters(found: String(ch)) }
            out.append(P[mod26(i + k)])
        }
        return out
    }

    static func decrypt(_ cipher: String, shift k: Int, keyword: String) throws -> String {
        guard (1...25).contains(k) else { throw CaesarError.invalidShift }
        let c = try sanitizeMessage(cipher)
        let P = try keywordAlphabet(keyword)
        var posInP: [Character:Int] = [:]
        for (i,ch) in P.enumerated() { posInP[ch] = i }
        var out = ""
        for ch in c {
            guard let j = posInP[ch] else { throw CaesarError.invalidLetters(found: String(ch)) }
            out.append(P[mod26(j - k)])
        }
        return out
    }
}

// MARK: - console demo

func prompt(_ text: String) -> String {
    print(text, terminator: " ")
    return readLine() ?? ""
}

func menu() {
    print("""
    =================================================================
    Caesar Lab – 1.1 & 1.2
    Only letters A–Z are accepted. Spaces are removed; everything uppercased.
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
    let choice = prompt("Alege opțiunea:")
    if choice == "0" { break }

    do {
        switch choice {
        case "1":
            let msg = prompt("Mesaj (doar litere, spațiile vor fi eliminate):")
            let k = Int(prompt("Cheie numerică (1…25):")) ?? -1
            let c = try Caesar.encrypt(msg, shift: k)
            print("Criptogramă:", c, "\n")
        case "2":
            let cip = prompt("Criptogramă:")
            let k = Int(prompt("Cheie numerică (1…25):")) ?? -1
            let m = try Caesar.decrypt(cip, shift: k)
            print("Mesaj decriptat:", m, "\n")
        case "3":
            let msg = prompt("Mesaj (doar litere, spațiile vor fi eliminate):")
            let k = Int(prompt("Cheie numerică (1…25):")) ?? -1
            let kw = prompt("Cheia 2 (keyword, litere A–Z, lungime ≥ 7):")
            let c = try CaesarWithPermutation.encrypt(msg, shift: k, keyword: kw)
            print("Criptogramă:", c, "\n")
        case "4":
            let cip = prompt("Criptogramă:")
            let k = Int(prompt("Cheie numerică (1…25):")) ?? -1
            let kw = prompt("Cheia 2 (keyword, litere A–Z, lungime ≥ 7):")
            let m = try CaesarWithPermutation.decrypt(cip, shift: k, keyword: kw)
            print("Mesaj decriptat:", m, "\n")
        default:
            print("Opțiune necunoscută.\n")
        }
    } catch {
        print("Eroare:", error, "\n")
    }
}
