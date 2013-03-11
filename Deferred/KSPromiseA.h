#import <Foundation/Foundation.h>

typedef id(^promiseValueCallback)(id);
typedef id(^promiseErrorCallback)(NSError *);

@interface KSPromiseA : NSObject
@property (strong, nonatomic, readonly) id value;
@property (strong, nonatomic, readonly) NSError *error;

- (KSPromiseA *)then:(promiseValueCallback)fulfilledCallback error:(promiseErrorCallback)errorCallback;
- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;

@end
