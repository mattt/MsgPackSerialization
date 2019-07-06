// main.m
//
// Copyright (c) 2013 – 2019 Mattt (https://mat.tt)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

#import "MsgPackSerialization.h"

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        id obj = @{
                   @"foo": @(42.0),
                   @"bar": @"lorem ipsum",
                   @"baz": @[@1, @2, @3, @4],
                   @"qux": [@"Hello, World" dataUsingEncoding:NSUTF8StringEncoding],
                   };

        uint64_t t = dispatch_benchmark(1000, ^{
            NSError *error = nil;
            NSData *data = [MsgPackSerialization dataWithMsgPackObject:obj options:0 error:&error];
            [MsgPackSerialization MsgPackObjectWithData:data options:0 error:&error];
        });

        NSLog(@"Average Runtime: %llu ns", t);
    }

    return 0;
}

