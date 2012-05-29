#import <Foundation/Foundation.h>

@class KSPromise;
typedef void(^deferredCallback)(KSPromise *);
typedef void(^deferredErrorCallback)(NSError *);

@interface KSPromise : NSObject

@property (strong, nonatomic) id value;
@property (strong, nonatomic) NSError *error;

- (KSPromise *)whenFulfilled:(deferredCallback)complete;
- (KSPromise *)whenResolved:(deferredCallback)complete;
- (KSPromise *)whenRejected:(deferredErrorCallback)complete;
- (void)cancel;

@end
