//
//  OAPMModuleEventTriger
//  OpenAPM
//
//  Created by 谢俊逸 on 3/5/2018.
//

#import "OAPMModuleEventTriger.h"
#import <objc/message.h>
@implementation OAPMModuleEventTriger
{
  BOOL _isRespond;
}
- (instancetype)initWithTargets:(NSMutableArray *)targets {
  _targets = targets;
  _isRespond = NO;
  return self;
}

+ (instancetype)proxyWithTargets:(NSMutableArray *)targets {
  return [[self alloc] initWithTargets:targets];
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  for (id target in _targets) {
    if ([target respondsToSelector:sel]) {
      return [target methodSignatureForSelector:sel];
    }
  }
  return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  SEL sel = invocation.selector;
  for (id target in _targets) {
    if ([target respondsToSelector:sel]) {
      [invocation invokeWithTarget:target];
    }
  }
}

@end