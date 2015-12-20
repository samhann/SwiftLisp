
import Foundation


func input() -> String
{
    print("lisp.swift >",terminator:"")
    return NSString(data: NSFileHandle.fileHandleWithStandardInput().availableData, encoding:NSUTF8StringEncoding) as! String
}


while true {
    do
    {
        var parsed = try parse(input())
        var evaled   = try eval(parsed)
        
        switch evaled  {
            case .Empty  : break;
            default     : print(evaled.strValue())
        }
    }
    catch Error.Error(message : let theMessage)
    {
        print(theMessage)
    }
}

    

