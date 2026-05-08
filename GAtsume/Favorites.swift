import Foundation

enum Favorites {
    static func parse(_ csv: String) -> Set<String> {
        Set(csv.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    static func encode(_ set: Set<String>) -> String {
        set.sorted().joined(separator: ",")
    }

    static func toggle(_ id: String, in csv: String) -> String {
        var set = parse(csv)
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
        return encode(set)
    }
}
