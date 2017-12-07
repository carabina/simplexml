/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 SimpleXML for Swift by Dylan Neild
 dylan@codeandstrings.com
 dylan@swimdrinkfish.ca
 */

import Foundation

public enum SimpleXMLError : Error {
    case urlRetrieveError
}

public class SimpleXML: NSObject, XMLParserDelegate {
    
    // MARK:- Class functions
    
    public class func parse(_ url : URL) throws -> [String:Any] {
        
        guard let urlParser = XMLParser(contentsOf: url) else {
            throw SimpleXMLError.urlRetrieveError
        }
        
        return try SimpleXML().parse(urlParser)
        
    }
    
    public class func parse(_ data : Data) throws -> [String:Any] {
        return try SimpleXML().parse(XMLParser(data: data))
    }

    public class func parse(_ stream : InputStream) throws -> [String:Any] {
        return try SimpleXML().parse(XMLParser(stream: stream))
    }
    
    // MARK:- Storage
    private var parsedData : [String:Any] = [:]
    
    // MARK:- Parse

    private func parse(_ parser : XMLParser) throws -> [String:Any] {
        parser.delegate = self
        parser.parse()
        return parsedData
    }
    
    // MARK:- Recursive Storage
    private var parent : SimpleXML!
    private var child : SimpleXML!
    private var dispatchedElementName : String!
    private var dispatchedAttributeDict : [String : String]!
    
    // MARK:- Constructors
    override init() {}
    
    init(_ parent : SimpleXML) {
        self.parent = parent
    }
    
    // MARK:- Temporary Parsing Storage
    private var stringBuffer : String?
    
    // MARK- Child Resumption
    private func store(_ newValue : Any) {
        if parsedData[dispatchedElementName] != nil && parsedData[dispatchedElementName] is [Any] {
            var targetArray = parsedData[dispatchedElementName] as! [Any]
            targetArray.append(newValue)
            parsedData[dispatchedElementName] = targetArray
        } else if parsedData[dispatchedElementName] != nil && parsedData[dispatchedElementName] is [String:Any] {
            let currentValue = parsedData[dispatchedElementName]!
            let replacementValue : [Any] = [currentValue, newValue]
            parsedData[dispatchedElementName] = replacementValue
        } else {
            parsedData[dispatchedElementName] = newValue
        }
    }
    
    private func concludeChildParsing (_ parser: XMLParser) {
        
        parsedData["&attributes"] = dispatchedAttributeDict

        if child.parsedData.count > 0 {
            store(child.parsedData)
        } else if let trimmedString = child.stringBuffer?.trimmingCharacters(in: .whitespacesAndNewlines) {
            store(trimmedString)
        } else {
            store("")
        }
        
        child = nil
        parser.delegate = self
        
    }
    
    // MARK:- XMLParser Delegates
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        dispatchedElementName = elementName
        dispatchedAttributeDict = attributeDict
        child = SimpleXML(self)
        parser.delegate = child
        
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        parent.concludeChildParsing(parser)
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if stringBuffer == nil {
            stringBuffer = String(string)
        } else {
            stringBuffer = stringBuffer!.appending(string)
        }
    }
    
    public func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let string : String = String(data: CDATABlock, encoding: .utf8) {
            self.parser(parser, foundCharacters: string)
        }
    }
    
    // MARK:- Diagnostic and Proofing
    
    private class func walkArray(_ key : String, _ array : [Any]) {
        for value in array {
            if value is [String:Any] {
                print("\(key) = {\t")
                debug(value as! [String:Any])
                print("}")
            }
            else if value is String {
                print("\(key) = (\((value as! String).count)) \(value)")
            }
            else if value is [Any] {
                walkArray(key, value as! [Any])
            }
        }
    }
    
    public class func debug (_ dictionary : [String:Any]) {
        for (key, value) in dictionary {
            if value is [String:Any] {
                print("\(key) = {\t")
                debug(value as! [String:Any])
                print("}")
            }
            else if value is String {
                print("\(key) = (\((value as! String).count)) \(value)")
            }
            else if value is [Any] {
                walkArray(key, value as! [Any])
            }
        }
    }
    
    
}
