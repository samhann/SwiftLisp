//:# LisPy.Swift - A Toy Lisp Interpreter

//: After reading [Peter Norvigs code](http://norvig.com/lispy.html) for a Lisp interpreter in Python , I decided to take a stab at in Swift. There is a lot more code due to the strong typing and my decision to implement atoms using Enums.


import Foundation

//:## Data structures

//: The most basic data structure is an atom , which can be a Number,a String,a Bool or a Nil.
enum Atom
{
    case Num(Float)
    case Symbol(String)
    case Boolean(Bool)
    case Nil
    
    func strValue()->String
    {
        switch self {
        case .Boolean(let bool):
            return String(bool)
        case .Symbol(let string):
            return string
        case .Num(let float):
            return String(float)
        case .Nil:
            return "NIL"
            
        }
    }
    
    func isBool() -> Bool {
        switch self {
        case .Boolean(_) : return true
        default          : return false
        }
    }
    
    func isNil() -> Bool {
        switch self {
        case .Nil        : return true
        default          : return false
        }
    }
    
}

//: The central data structure is the s-expression which is either an atom or a composition of two s-expressions. 
//: The other two cases are just added to make the implementation easier.

enum sExp
{
    case Atomic(Atom)
    case Lambda(sExp throws ->sExp)
    indirect case  Cons(sExp,sExp)
    case Empty
    
    func strValue()->String
    {
        switch self {
        case .Atomic(let atom):
            return atom.strValue()
        case .Lambda(_):
            return "Lambda"
        case .Cons(let f, let s):
            return "("+f.strValue() + "," + s.strValue()+")"
        case Empty:
            return "Void"
        }
    }
    
    func isNil()->Bool
    {
        switch self {
            case .Atomic(let atom) : return atom.isNil()
            default : return false
        }
    }
    
    func floatValue() throws -> Float
    {
        switch self {
            case .Atomic(let atom):
                switch atom {
                case .Num(let float):
                    return float
                case .Boolean(let bool):
                    return bool ? 1.0 : 0.0
                default:
                    throw Error.Error(message: "Could not cast exp to float")
                }
            case .Cons(let f, _):
                return try f.floatValue()
            default:
                throw Error.Error(message: "Could not cast exp to float")
        }
    }
    
    func stringValue() throws -> String
    {
        switch self {
        case.Atomic(let atom):
            switch atom {
            case .Symbol(let string):
                return string
            default :
                throw Error.Error(message: "Tried to stringValue of non string")
            }
            
        default:
            throw Error.Error(message: "Tried to get stringValue of non string")
        }
    }
    
    func boolValue() throws -> Bool
    {
        switch self {

        case.Atomic(let atom):
        
            switch atom {
            
                case .Boolean(let bool):
                        return bool
                    case .Nil:
                        return false
                    default :
                        return true
                    }
            
                default:
                    return true
            }
    }
}

enum Error : ErrorType
{
    case Error(message : String)
}

//:# Functions
//: Cons joins two sExpressions together

func cons(let first : sExp , second : sExp)-> sExp
{
    return .Cons(first,second)
}

//: (cons 1 2) => (1 2)

//: car gives you the head of a cons
func car(let exp : sExp) throws -> sExp
{
    switch exp {
    case .Cons(let first,  _):
        return first
    case .Atomic(_):
        return exp
    default:
        throw Error.Error(message:"CAR called with non list")
    }
}

//: cdr gives you the tail or rest of the cons
func cdr(let exp : sExp) throws -> sExp
{
    switch exp {
    case .Cons( _,  let second):
        return second
    default:
        throw Error.Error(message:"CDR called with non list")
        
    }
}

//: append appends an sExp to the end of a list. A list a series of cons cells with the first element being the member of the list and the cdr or second element pointing to the next cons cell in the list. The last element has its cdr pointing to nil.

func append(let first: sExp?, second : sExp) throws -> sExp
{
    if let firstExp = first {
        switch firstExp {
        case .Atomic( _):
            return .Cons(second,firstExp)
        case .Cons(let f,let s):
            return .Cons(f,try append(s, second: second))
        default:
            throw Error.Error(message: "Cannot append")
        }
    }
        
    else
    {
        return second
    }
}

//: Tokenize splits a string into an array. A simple tokeniser that doesnt allow spaces in expressions.

func tokenize(chars : String)->[String]
{
    let split : [String] =  chars.stringByReplacingOccurrencesOfString("(", withString: " ( ").stringByReplacingOccurrencesOfString(")", withString: " ) ").componentsSeparatedByString(" ").filter { $0 != ""}
    
    return split
}

//: Converts a string into an atom.

func atom(token : String)->Atom
{
    if let integer = Int(token) {
        return .Num(Float(integer))
    }
    
    if let float = Float(token) {
        return .Num(float)
    }
        
    else {
        return .Symbol(token)
    }
}

//: Implementations of map,reduce and some helper methods for making the standard functions

func lMap(let exp : sExp , let lambda : sExp) throws ->sExp
{
    do {
        switch lambda {
        case .Lambda(let aLambda):
            switch exp {
                case .Atomic(let atom):
                    switch atom {
                    case .Nil:
                        return exp
                    default:
                        return try aLambda(exp)
                    }
                    
                case .Cons(let first, let second):
                    return  .Cons(try aLambda(first),try lMap(second, lambda: .Lambda(aLambda)))
                default:
                    throw Error.Error(message: "Expression to be mapped over is not an expression")
            }
        default:
            throw Error.Error(message: "Expected lambda in call to map")
        }
    }
}

func lReduce(let initialValue : sExp , let reducer : sExp throws ->sExp , let exp : sExp) throws ->sExp
{
    switch exp {
    case .Cons(let first, let second):
        
        return try lReduce(try reducer(.Cons(initialValue,first)), reducer: reducer, exp: second)
    case .Atomic(let atom):
        
        switch atom {
        case .Nil:
            return initialValue
        default:
            return  try reducer(.Cons(initialValue, exp))
        }
        
        
    default:
        throw Error.Error(message: "cannot reduce")
    }
    
}

func reduceWithFirst(let reducer : sExp throws -> sExp , let exp : sExp) throws -> sExp
{
    switch exp {
    case .Cons(let f, let s):
        return try lReduce(f, reducer: reducer, exp: s)
    case .Atomic(_):
        return try lReduce(exp, reducer: reducer, exp: .Atomic(.Nil))
    default:
        throw Error.Error(message: "Reducer got invalid exp")
    }
    
}

func binaryNumericOp(let first : sExp , let second : sExp, let lambda :(Float,Float)->Float) throws -> sExp
{
    return try .Atomic(.Num(lambda(first.floatValue(),second.floatValue())))
}

func binaryBoolOp(let exp : sExp , let lambda: (Float,Float)->Bool) throws -> sExp
{
    switch exp {
    case .Cons(let f , let s):
        return try .Atomic(.Boolean(lambda(f.floatValue(),car(s).floatValue())))
    default:
        throw Error.Error(message: "Invalid arguments to boolean operator")
    }
}


func executeFloatLambda( expr : sExp , let aLambda : (Float,Float)->Float) throws -> sExp
{
    switch expr {
    case .Cons(let f, let s):
        return try binaryNumericOp(f, second: s, lambda: aLambda)
    default:
        throw Error.Error(message: "Reducer got invalid arguments")
    }
}

func makeFloatReducer(theLambda : (Float,Float)-> Float)->sExp throws -> sExp
{
    return { sExp in
            return try reduceWithFirst({ (theExp) in
                return try executeFloatLambda(theExp, aLambda: theLambda)
            },exp: sExp)
    }
}

//: We tokenise the program by recursively parsing it and appending it to an sExp.

var globalTokens : [String] = []

func readFromTokens() throws -> sExp
{
    do {
        if globalTokens.count == 0 {
            throw Error.Error(message:"Parsing error")
        }
        
        let token = globalTokens.removeFirst()
        if globalTokens.count == 0 {
            throw Error.Error(message:"Parsing error")
        }
        
        if "(" == token {
            var L  : sExp = .Atomic(.Nil)
            
            
            while globalTokens[0] != ")" {
                let exp =  try readFromTokens()
                L = try append(L,second: exp)
                if globalTokens.count == 0 {
                    throw Error.Error(message:"Parsing error")
                }
            }
            globalTokens.removeFirst()
            return L
        }
        else if ")" == token {
            throw Error.Error(message:"Unexpected end of expression")
        }
        else {
            return sExp.Atomic(atom(token))
        }
    }
}

func parse(let program : String) throws ->sExp
{
    globalTokens  = tokenize(program)
    return try readFromTokens()
}

//: The environment to hold all the global functions and constants. Each environment has a pointer to an outer enclosing scope which helps to implement lambdas (which create a new scope).

class Environment
{
    var dictionary : Dictionary<String,sExp>
    var outer      : Environment?
    
    init(let anOuter : Environment? = nil)
    {
        self.outer = anOuter
        self.dictionary = [
            
            "*" : .Lambda(makeFloatReducer {$0 * $1}),
            "+" : .Lambda(makeFloatReducer {$0 + $1}),
            "-" : .Lambda(makeFloatReducer {$0 - $1}),
            "/" : .Lambda(makeFloatReducer {$0 / $1}),
            "max" : .Lambda({ (exp:sExp)throws ->sExp in return try makeFloatReducer { return $0 > $1 ? $0 : $1}(try car(exp))}),
            "min" : .Lambda({ (exp:sExp)throws ->sExp in return try makeFloatReducer { return $0 < $1 ? $0 : $1}(try car(exp))}),
            ">"     : .Lambda({ return try binaryBoolOp($0, lambda: { $0 > $1}) }),
            "<"     : .Lambda({ return try binaryBoolOp($0, lambda: { $0 < $1}) }),
            ">="    : .Lambda({ return try binaryBoolOp($0, lambda: { $0 >= $1}) }),
            "<="    : .Lambda({ return try binaryBoolOp($0, lambda: { $0 <= $1}) }),
            "="     : .Lambda({ return try binaryBoolOp($0, lambda: { $0 == $1}) }),
            "car"   : .Lambda({ return try car(car($0))}),
            "cdr"   : .Lambda( { return try cdr(car($0))}),
            "abs"   : .Lambda( { return  .Atomic(.Num(abs(try $0.floatValue())))}),
            "round" : .Lambda( { return  .Atomic(.Num(round(try $0.floatValue())))}),
            "cons"  : .Lambda( { return try cons(car($0), second: car(cdr($0))) }),
            "map"   : .Lambda( { return try lMap(try car(cdr($0)), lambda: try car($0))}),
            "list"  : .Lambda( { return $0}),
            "null?" : .Lambda( { return .Atomic(.Boolean( $0.isNil())) }),
            "pi" : sExp.Atomic(.Num(Float(M_PI)))
        ]
    }
    
    func get(let x : String) throws ->sExp
    {
        if let value = self.dictionary[x] {
            return value
        }
        else {
            
            if let theOuter = self.outer {
                return try theOuter.get(x)
            }
            else {
                throw Error.Error(message: "Could not find " + x + " in the environment")
            }
            
        }
    }
    
    func set(let x : String, let val : sExp)
    {
        self.dictionary[x] = val
    }
    
    func update(let params: sExp , let args : sExp) throws  -> Environment
    {
        switch params {
        case .Cons(let f, let s):
            self.set(try f.stringValue(), val: try car(args))
            switch s {
            case .Cons(_, _):
                return try self.update(s, args: try cdr(args))
            default:
                break;
            }
            
        default: break
        }
        return self
        
    }
    
}

var globalEnv = Environment()

//: The heart of the program which evals an expression to produce a result.
//: executeProc captures the lambda scope in a closure for later execution.

func eval_atom(let x : sExp , let env : Environment = globalEnv) throws ->sExp
{
    switch x {
    case .Atomic(let atom) :
        switch atom {
        case .Symbol(let name):
            return try env.get(name)
        default:
            return x
        }
        
    default :
        throw Error.Error(message:"Couldnt parse atom")
        
    }
}

func executeProc( let lambda :sExp ,let args: sExp, let env : Environment)->sExp throws ->sExp
{
    return { params in
        return try eval(lambda , env: Environment(anOuter: env).update(args, args: params))
    }
}


func eval (let x : sExp ,let env : Environment = globalEnv) throws ->sExp
{
    do
    {
        switch(x) {
            
        case .Cons(let first, let second):
            
            switch first {
                
            case .Atomic( _):
                
                let string = try first.stringValue()
                
                switch string {
                case "define":
                    let theVar = try car(second).stringValue()
                    let theRest = try car(cdr(second))
                    env.set(theVar, val: try eval(theRest,env: env))
                    return .Empty
                    
                case "if":
                    let test = try eval(car(second),env:env).boolValue()
                    let conseq = try car(cdr(second))
                    let alt     = try car(cdr(cdr(second)))
                    let exp = test ? conseq : alt
                    return try eval(exp,env: env)
                    
                case "quote":
                    return try car(second)
                    
                case "lambda":
                    let args = try car(second)
                    let body = try car((cdr(second)))
                    return .Lambda({ params in  return try executeProc( body, args: args, env: env)(params)})
                default:
                    return try eval_lambda(first, second: second, env: env)
                    
                }
            case .Cons(_, _):
                switch x {
                case .Cons(let ff, let ss):
                    return try eval_lambda(ff, second: ss, env: env)
                default:
                    throw Error.Error(message: "EVAL Error")
                }
                
                
            default:
                throw Error.Error(message: "Unhandled case in eval")
            }
        case .Atomic( _):
            return try eval_atom(x,env: env)
            
        default:
            throw Error.Error(message: "EVAL Error")
        }
    }
}

func eval_lambda(let first : sExp , let second : sExp,let env : Environment) throws -> sExp
{
    let evaledFirst = try eval(first,env : env)
    switch evaledFirst {
    case .Lambda(let aLambda):
        let evaledRest = try lMap(second, lambda: .Lambda({ anExp in return try eval(anExp,env: env)}))
        return try aLambda(evaledRest)
        
    default :
        throw Error.Error(message: "Tried to call a non lambda")
        
    }
}

var program = "(+ 1 2)"

//: Uncomment this to run it in the playground.

//print(try eval(parse(program)))
