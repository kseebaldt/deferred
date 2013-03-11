#import "KSDeferred.h"

@interface KSPromise (Deferred)
- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;
@end

@implementation KSDeferred

@synthesize promise = _promise;

+ (KSDeferred *)defer {
    return [[KSDeferred alloc] init];
}

- (id)init {
    self = [super init];
    if (self) {
        self.promise = [[KSPromise alloc] init];
        self.promiseA = [[KSPromiseA alloc] init];
    }
    return self;
}

- (void)resolveWithValue:(id)value {
    [self.promise resolveWithValue:value];
}

- (void)rejectWithError:(NSError *)error {
    [self.promise rejectWithError:error];
//    [self.promiseA rejectWithError:error];
}

- (void)fullfillWithValue:(id)value {
//    [self.promiseA fulfillWithValue:value];
}

@end
