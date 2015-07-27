#import "KSDeferred.h"

@interface KSPromise KS_GENERIC(ObjectType) (Deferred)
- (void)resolveWithValue:(KS_GENERIC_TYPE(ObjectType))value;
- (void)rejectWithError:(NSError *)error;
@end

@interface KSDeferred () <KSCancellable>
@property (copy, nonatomic) void (^cancelledBlock)(void);
@property (nonatomic) BOOL cancelled;
@end

@implementation KSDeferred

@synthesize promise = _promise;

+ (instancetype)defer {
    return [[self alloc] init];
}

- (id)init {
    self = [super init];
    if (self) {
        self.promise = [[KSPromise alloc] init];
        [self.promise addCancellable:self];
    }
    return self;
}

- (void)resolveWithValue:(id)value {
    if (!self.cancelled) {
        [self.promise resolveWithValue:value];
    }
}

- (void)rejectWithError:(NSError *)error {
    if (!self.cancelled) {
        [self.promise rejectWithError:error];
    }
}

- (void)whenCancelled:(void (^)(void))cancelledBlock
{
    self.cancelledBlock = cancelledBlock;
}

- (void)fullfillWithValue:(id)value {
}

- (void)cancel
{
    if (!self.cancelled) {
        self.cancelled = YES;
        if (self.cancelledBlock) {
            self.cancelledBlock();
        }
    }
}

@end
