MsgPackSerialization
====================

`MsgPackSerialization` encodes and decodes between Objective-C objects and [MsgPack](http://msgpack.org) data, following the API conventions of Foundation's `NSJSONSerialization` class.

## Usage

```objective-c
id obj = @{
           @"foo": @(42.0),
           @"bar": @"lorem ipsum",
           @"baz": @[@1, @2, @3, @4]
           };

NSError *error = nil;

CFAbsoluteTime t_0 = CFAbsoluteTimeGetCurrent();
NSData *data = [MsgPackSerialization dataWithMsgPackObject:obj options:0 error:&error];
NSLog(@"Packed: %@ (Elapsed: %g)", data, CFAbsoluteTimeGetCurrent() - t_0);

CFAbsoluteTime t_1 = CFAbsoluteTimeGetCurrent();
NSLog(@"Unpacked: %@ (Elapsed: %g)", [MsgPackSerialization MsgPackObjectWithData:data options:0 error:&error], CFAbsoluteTimeGetCurrent() - t_1);
```

---

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

## License

MsgPackSerialization is available under the MIT license. See the LICENSE file for more info.
