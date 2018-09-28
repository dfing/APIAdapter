// comment

import UIKit

var str = "Hello, playground"

let anotherQueue1 = DispatchQueue(label: "com.appcoda.anotherQueue", qos: .background)
let anotherQueue2 = DispatchQueue(label: "com.appcoda.anotherQueue", qos: .default)
anotherQueue1.sync {
    for i in 0..<10 {
        print("🍎 \(i)")
    }
}

anotherQueue2.async {
    for i in 100..<110 {
        print("🍏 \(i)")
    }
}


for i in 1000..<1010 {
    print("🍆 \(i)")
}

//let myQueue = DispatchQueue(label: "my.queue", attributes: .concurrent)
//let workItem = DispatchWorkItem {
//    sleep(1)
//    print("done")
//}
//myQueue.async(execute: workItem)
//print("before waiting")
//workItem.wait()
//print("after waiting")

