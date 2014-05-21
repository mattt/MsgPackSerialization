// MsgPackSerialization.m
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

#import "MsgPackSerialization.h"

#import "msgpack.h"

NSString * const MsgPackErrorDomain = @"com.msgpack.error";

static void MsgPackEncode(id obj, MsgPackWritingOptions opt, msgpack_packer *pk, NSError * __autoreleasing *error) {
    if ([obj isKindOfClass:[NSArray class]]) {
		msgpack_pack_array(pk, (unsigned int)[(NSArray *)obj count]);
		for (id item in obj) {
			MsgPackEncode(item, opt, pk, error);
		}
	} else if ([obj isKindOfClass:[NSDictionary class]]) {
		msgpack_pack_map(pk, (unsigned int)[(NSDictionary *)obj count]);
		for(id key in obj) {
            MsgPackEncode(key, opt, pk, error);
            MsgPackEncode(obj[key], opt, pk, error);
		}
	} else if ([obj isKindOfClass:[NSString class]]) {
		const char *str = [(NSString*)obj UTF8String];
		unsigned long len = strlen(str);
		msgpack_pack_raw(pk, len);
		msgpack_pack_raw_body(pk, str, len);
	} else if ([obj isKindOfClass:[NSNumber class]]) {
        switch (*[obj objCType]) {
            case 's':
                msgpack_pack_int16(pk, [(NSNumber *)obj shortValue]);
                break;
            case 'S':
                msgpack_pack_int16(pk, [(NSNumber *)obj unsignedShortValue]);
                break;
            case 'i':
            case 'l':
                msgpack_pack_int32(pk, [(NSNumber *)obj intValue]);
                break;
            case 'I':
            case 'L':
                msgpack_pack_int32(pk, [(NSNumber *)obj unsignedIntValue]);
                break;
            case 'q':
                msgpack_pack_int64(pk, [(NSNumber *)obj longLongValue]);
                break;
            case 'f':
                msgpack_pack_float(pk, [(NSNumber *)obj floatValue]);
                break;
            case 'd':
                msgpack_pack_double(pk, [(NSNumber *)obj doubleValue]);
                break;
            case 'c':
            case 'C': {
                switch ([(NSNumber *)obj intValue]) {
                    case 0:
                        msgpack_pack_false(pk);
                        break;
                    case 1:
                        msgpack_pack_true(pk);
                        break;
                    default:
                        msgpack_pack_int8(pk, [(NSNumber *)obj charValue]);
                        break;
                }
            }
                break;
            default: {
                goto _error;
            }
        }
	} else if ([obj isEqual:[NSNull null]]) {
		msgpack_pack_nil(pk);
	} else {
		goto _error;
	}

_error:

    if (error) {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Could Not Encode Object: %@", @"MsgPackSerialization", nil), obj]
                                   };

        *error = [[NSError alloc] initWithDomain:MsgPackErrorDomain code:0 userInfo:userInfo];
    }
}

static id MsgPackDecode(msgpack_object obj, MsgPackReadingOptions opt, __unused NSError * __autoreleasing *error) {
    switch (obj.type) {
        case MSGPACK_OBJECT_BOOLEAN:
            return @(obj.via.boolean);
        case MSGPACK_OBJECT_POSITIVE_INTEGER:
            return @(obj.via.u64);
        case MSGPACK_OBJECT_NEGATIVE_INTEGER:
            return @(obj.via.i64);
        case MSGPACK_OBJECT_DOUBLE:
            return @(obj.via.dec);
        case MSGPACK_OBJECT_RAW: {
            
            NSMutableString * mutableString = [[NSMutableString alloc] initWithBytes:obj.via.raw.ptr length:obj.via.raw.size encoding:NSUTF8StringEncoding];
            if(!mutableString)
            {
                NSMutableData * mutableData =  [[NSMutableData alloc] initWithBytes:obj.via.raw.ptr length:obj.via.raw.size];
                return (opt & MsgPackReadingMutableLeaves) ? mutableData : [NSData dataWithData:mutableData];
            }
            else
            {
               return (opt & MsgPackReadingMutableLeaves) ? mutableString : [NSString stringWithString:mutableString];
            }
            
        }
        case MSGPACK_OBJECT_ARRAY: {
            NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:obj.via.array.size];
            msgpack_object * const arr = obj.via.array.ptr + obj.via.array.size;
            for (msgpack_object *p = obj.via.array.ptr; p < arr; p++) {
                [mutableArray addObject:MsgPackDecode(*p, opt, error)];
            }

            return (opt & MsgPackReadingMutableContainers) ? mutableArray : [NSArray arrayWithArray:mutableArray];
        }
        case MSGPACK_OBJECT_MAP: {
            NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithCapacity:obj.via.map.size];
            msgpack_object_kv * const kv = obj.via.map.ptr + obj.via.map.size;
            for (msgpack_object_kv *p = obj.via.map.ptr; p < kv; p++) {
                id key = MsgPackDecode(p->key, opt, error);
                id value = MsgPackDecode(p->val, opt, error);
                
                if ([key isKindOfClass:[NSData class]])
                {
                    key = [[NSString alloc] initWithData:key encoding:NSUTF8StringEncoding];
                }
                
                if ((key && ![key isEqual:[NSNull null]])) {
                    mutableDictionary[key] = value;
                }
            }

            return (opt & MsgPackReadingMutableContainers) ? mutableDictionary : [NSDictionary dictionaryWithDictionary:mutableDictionary];
        }
        case MSGPACK_OBJECT_NIL:
        default:
            return [NSNull null];
    }
}

@implementation MsgPackSerialization

+ (id)MsgPackObjectWithData:(NSData *)data
                    options:(MsgPackReadingOptions)opt
                      error:(NSError **)error
{
    if (!data || [data length] == 0) {
        return nil;
    }

    id obj = nil;

    msgpack_unpacked msg;
	msgpack_unpacked_init(&msg);
    if (msgpack_unpack_next(&msg, data.bytes, data.length, NULL)) {
        obj = MsgPackDecode(msg.data, opt, error);
    }
	msgpack_unpacked_destroy(&msg);

    return obj;
}

#pragma mark -

+ (NSData *)dataWithMsgPackObject:(id)obj
                          options:(MsgPackWritingOptions)opt
                            error:(NSError **)error
{
    if (!obj) {
        return nil;
    }

	msgpack_sbuffer *buffer = msgpack_sbuffer_new();
	msgpack_packer *pk = msgpack_packer_new(buffer, msgpack_sbuffer_write);

	MsgPackEncode(obj, opt, pk, error);
	NSData *data = [NSData dataWithBytes:buffer->data length:buffer->size];

	msgpack_sbuffer_free(buffer);
	msgpack_packer_free(pk);

    return data;
}

+ (NSInteger)writeMsgPackObject:(id)obj
                       toStream:(NSOutputStream *)stream
                        options:(MsgPackWritingOptions)opt
                          error:(NSError **)error
{
    NSData *data = [self dataWithMsgPackObject:obj options:opt error:error];
    if (data) {
        return [stream write:[data bytes] maxLength:[data length]];
    }

    return -1;
}

+ (BOOL)isValidMsgPackObject:(id)obj {
    return [NSJSONSerialization isValidJSONObject:obj];
}

@end
