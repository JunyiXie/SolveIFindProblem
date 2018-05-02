//
//  OAPMManager.m
//  OpenAPM
//
//  Created by 谢俊逸 on 1/5/2018.
//

#import "OAPMManager.h"
#import "OAPMConfigProtocol.h"
#import "OAPMModuleProtocol.h"
#import "OAPMServiceProtocol.h"
#import "OAPMConfig.h"


// 全都搞成单例？
@interface OAPMModuleManager: NSObject
{
  NSMutableArray<id<OAPMModuleProtocol>> *_moduleClss;
}

- (void)addModuleCls:(Class<OAPMModuleProtocol>)cls;
- (id<OAPMModuleProtocol>)moduleSingletonFromProtocol:(Protocol *)protocol;
@end
@implementation OAPMModuleManager
+ (instancetype)shared {
  static dispatch_once_t onceToken;
  static OAPMModuleManager *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [OAPMModuleManager new];
  });
  return instance;
}
- (instancetype)init {
  if (self = [super init]) {
    _moduleClss = [NSMutableArray new];
  }
  return self;
}
- (void)addModuleCls:(Class<OAPMModuleProtocol>)cls {
  [_moduleClss addObject:cls];
}
- (id<OAPMModuleProtocol>)moduleSingletonFromProtocol:(Protocol *)protocol {
  for (id<OAPMModuleProtocol> module in _moduleClss) {
    if ([module conformsToProtocol:protocol]) {
      return [module shared];
    }
  }
  return nil;
}
@end



@interface OAPMServiceManager: NSObject
{
  NSMutableArray<NSDictionary *> *_serviceDics;
}
- (id<OAPMServiceProtocol>)serviceSingletonFromProtocol:(Protocol *)protocol;
- (void)addServiceDic:(NSDictionary *)serviceDic;
@end



@implementation OAPMServiceManager
+ (instancetype)shared {
  static dispatch_once_t onceToken;
  static OAPMServiceManager *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [OAPMServiceManager new];
  });
  return instance;
}
- (instancetype)init {
  if (self = [super init]) {
    _serviceDics = [NSMutableArray new];
  }
  return self;
}
- (void)addServiceDic:(NSDictionary *)serviceDic {
  [_serviceDics addObject:serviceDic];
}
- (id<OAPMServiceProtocol>)serviceSingletonFromProtocol:(Protocol *)protocol {
  NSString *protocolStr = NSStringFromProtocol(protocol);
  for (NSDictionary *dic in _serviceDics) {
    if (dic[protocolStr]) {
      Class<OAPMServiceProtocol> cls = NSClassFromString(dic[protocolStr]);
      return [cls shared];
    }
  }
  return nil;
}

@end




@interface OAPMManager()
{
  NSMutableArray<id<OAPMModuleProtocol>> *_moduleClss;
  NSMutableArray<NSDictionary *> *_serviceDics;
}
@end

@implementation OAPMManager

+ (instancetype)shared {
  static dispatch_once_t onceToken;
  static OAPMManager *instance = nil;
  dispatch_once(&onceToken, ^{
    instance = [OAPMManager new];
  });
  return instance;
}

- (instancetype)init {
  if (self = [super init]) {
    _moduleClss = [NSMutableArray new];
    _serviceDics = [NSMutableArray new];
  }
  return self;
}

/// 做 module <-> serviceprotocol <-> configprotocol 的 绑定
/// 根据module -> configprotocol,  自己做个 configuration array , conform protocol.. 做个分发把。
/// 把configuration都拆成各种对象。
- (void)triggerModuleStartEventWithConfig:(NSMutableArray<id<OAPMConfigurationProtocol>>*)configs {
  ///
}



- (void)registerModuleCls:(Class<OAPMModuleProtocol>)module {
  [[OAPMModuleManager shared] addModuleCls:module];
//  [[OAPMModuleManager shared] addModuleCls:module];
}

- (void)registerService:(Protocol *)protocol implClass:(Class)class {
  NSString *protocolStr = NSStringFromProtocol(protocol);
  NSString *impClsStr = NSStringFromClass(class);
  NSDictionary *dic = @{protocolStr:impClsStr};
  [[OAPMServiceManager shared] addServiceDic:dic];
}

- (id<OAPMServiceProtocol>)serviceFromProtocol:(Protocol *)protocol {
  return [[OAPMServiceManager shared] serviceSingletonFromProtocol:protocol];
//  NSString *protocolStr = NSStringFromProtocol(protocol);
//  for (NSDictionary *dic in _serviceDics) {
//    if (dic[protocolStr]) {
//      Class<OAPMServiceProtocol> cls = NSClassFromString(dic[protocolStr]);
//      return [cls shared];
//    }
//  }
//  return nil;
}

- (id<OAPMModuleProtocol>)moduleFromProtocol:(Protocol *)protocol {
//  for (id<OAPMModuleProtocol> module in _moduleClss) {
//    if ([module conformsToProtocol:protocol]) {
//      return [module shared];
//    }
//  }
//  return nil;
  return [[OAPMModuleManager shared] moduleSingletonFromProtocol:protocol];
}



#pragma mark - Event
- (void)trigerEvent:(OAPMModuleEvent)event {
  switch (event) {
    case ModuleStart:
    {
      [[OAPMConfig shared] trigerStartEventForModuleClss:_moduleClss];
    }
      break;
    default:
      break;
  }
}


#pragma mark - Dyld  Discover Module Service
NSArray<NSString *>* BHReadConfiguration(char *sectionName,const struct mach_header *mhp);
static void dyld_callback(const struct mach_header *mhp, intptr_t vmaddr_slide)
{
  NSArray *mods = BHReadConfiguration(BeehiveModSectName, mhp);
  for (NSString *modName in mods) {
    Class cls;
    if (modName) {
      cls = NSClassFromString(modName);
      
      if (cls) {
        [[OAPMManager shared] registerModuleCls:cls];
      }
    }
  }
  
  //register services
  NSArray<NSString *> *services = BHReadConfiguration(BeehiveServiceSectName,mhp);
  for (NSString *map in services) {
    NSData *jsonData =  [map dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (!error) {
      if ([json isKindOfClass:[NSDictionary class]] && [json allKeys].count) {
        
        NSString *protocol = [json allKeys][0];
        NSString *clsName  = [json allValues][0];
        
        if (protocol && clsName) {
          [[OAPMManager shared] registerService:NSProtocolFromString(protocol) implClass:NSClassFromString(clsName)];
        }
        
      }
    }
  }
  
}
__attribute__((constructor))
void initProphet() {
  _dyld_register_func_for_add_image(dyld_callback);
}

NSArray<NSString *>* BHReadConfiguration(char *sectionName,const struct mach_header *mhp)
{
  NSMutableArray *configs = [NSMutableArray array];
  unsigned long size = 0;
#ifndef __LP64__
  uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
#else
  const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
  uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
#endif
  
  unsigned long counter = size/sizeof(void*);
  for(int idx = 0; idx < counter; ++idx){
    char *string = (char*)memory[idx];
    NSString *str = [NSString stringWithUTF8String:string];
    if(!str)continue;
    
    NSLog(@"config = %@", str);
    if(str) [configs addObject:str];
  }
  
  return configs;
  
  
}

@end