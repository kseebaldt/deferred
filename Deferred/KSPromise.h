#import <Foundation/Foundation.h>

@class KSPromise;

typedef id(^promiseValueCallback)(id);
typedef id(^promiseErrorCallback)(NSError *);
typedef void(^deferredCallback)(KSPromise *);

@interface KSPromise : NSObject
@property (strong, nonatomic, readonly) id value;
@property (strong, nonatomic, readonly) NSError *error;

+ (KSPromise *)join:(NSArray *)promises;

- (KSPromise *)then:(promiseValueCallback)fulfilledCallback error:(promiseErrorCallback)errorCallback;
- (void)cancel;

#pragma deprecated
- (void)whenResolved:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenRejected:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenFulfilled:(deferredCallback)complete DEPRECATED_ATTRIBUTE;


@end
