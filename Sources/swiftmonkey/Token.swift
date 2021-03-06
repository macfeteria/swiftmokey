
public enum TokenType:String {
    case ILLEGAL = "ILLEGAL"
    case EOF     = "EOF"
    
    // Identifier & Literal
    case IDENT = "IDENT"
    case INT   = "INT"
    
    // Operator
    case ASSIGN = "="
    
    case EQUAL = "=="
    case NOTEQUAL = "!="

    case PLUS   = "+"
    case MINUS  = "-"
    case BANG   = "!"
    case ASTERISK  = "*"
    case SLASH = "/"
    
    case GREATER = ">"
    case LESSTHAN = "<"

    // Delimiters
    case COMMA     = ","
    case SEMICOLON = ";"
    
    case LPAREN = "("
    case RPAREN = ")"
    case LBRACE = "{"
    case RBRACE = "}"
    
    case LBRACKET = "["
    case RBRACKET = "]"
    
    case COLON = ":"
    
    // Keywords
    case FUNCTION = "FUNCTION"
    case LET      = "LET"
    case TRUE     = "TRUE"
    case FALSE    = "FALSE"
    case IF       = "IF"
    case ELSE     = "ELSE"
    case RETURN   = "RETURN"
    case STRING   = "STRING"
    
}

public struct Token {
    var `type`:TokenType
    var literal:String
}

let keywords = [ "fn": TokenType.FUNCTION,
                 "let" : TokenType.LET,
                 "true" : TokenType.TRUE,
                 "false" : TokenType.FALSE,
                 "if" : TokenType.IF,
                 "else" : TokenType.ELSE,
                 "return" : TokenType.RETURN,
]

func lookupIdent(ident:String) -> TokenType {
    if let key = keywords[ident] {
        return key
    } else {
        return TokenType.IDENT
    }
}
