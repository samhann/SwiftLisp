
import Foundation


func input() -> String
{
    print("lisp.swift >",terminator:"")
    return NSString(data: NSFileHandle.fileHandleWithStandardInput().availableData, encoding:NSUTF8StringEncoding) as! String
}


do {
    while true {
        var parsed = try parse(input())
        print(try eval(parsed).strValue())
    }
}
    
catch Error.Error(message : let theMessage)
{
    print(theMessage)
}

