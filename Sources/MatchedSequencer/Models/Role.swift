import Foundation

// Make the enum public so it can be used in public function signatures
public enum Role: Hashable {
    case source
    case destination
    case transition
} 
