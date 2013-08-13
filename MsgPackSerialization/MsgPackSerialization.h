// MsgPackSerialization.h
// 
// Copyright (c) 2013 Mattt Thompson (http://mattt.me)
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

typedef NS_OPTIONS(NSUInteger, MsgPackReadingOptions) {
    MsgPackReadingMutableContainers = (1UL << 0),
    MsgPackReadingMutableLeaves = (1UL << 1),
};

//typedef NS_OPTIONS(NSUInteger, MsgPackWritingOptions) {};
typedef NSUInteger MsgPackWritingOptions;

/**
 
 */
@interface MsgPackSerialization : NSObject

///--------------------------------
/// @name Creating a MsgPack Object
///--------------------------------

/**
 
 */
+ (id)MsgPackObjectWithData:(NSData *)data
                    options:(MsgPackReadingOptions)opt
                      error:(NSError **)error;

/**
 
 */
//+ (id)MsgPackObjectWithStream:(NSInputStream *)stream
//                      options:(MsgPackReadingOptions)opt
//                        error:(NSError **)error;

///----------------------------
/// @name Creating MsgPack Data
///----------------------------

/**
 
 */
+ (NSData *)dataWithMsgPackObject:(id)obj
                          options:(MsgPackWritingOptions)opt
                            error:(NSError **)error;

/**
 
 */
+ (NSInteger)writeMsgPackObject:(id)obj
                       toStream:(NSOutputStream *)stream
                        options:(MsgPackWritingOptions)opt
                          error:(NSError **)error;

/**
 
 */
+ (BOOL)isValidMsgPackObject:(id)obj;

@end

///----------------
/// @name Constants
///----------------

/**
 
 */
extern NSString * const MsgPackErrorDomain;
