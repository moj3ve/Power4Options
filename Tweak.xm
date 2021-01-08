#import <substrate.h>
#import <spawn.h>
#import <UIKit/UIKit.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_13_0
#define kCFCoreFoundationVersionNumber_iOS_13_0 1665.15
#endif

@interface _UIActionSlider : NSObject

@property (nonatomic, retain) UIImage * knobImage;

-(id)_knobView;
-(void)setTrackText:(NSString *)arg1;
-(void)setKnobImage:(UIImage *)arg1;

- (UIImageView*)knobImageView;
- (void)setColorKnobImage:(UIColor*)color;

@end

@interface FBSystemService : NSObject
-(void)shutdownAndReboot:(BOOL)arg1;
-(void)exitAndRelaunch:(BOOL)arg1;
@end

@interface POMode : NSObject {
  NSString* mode;
}
+(instancetype)sharedInstance;
-(void)setMode:(NSString*)m;
-(NSString*)mode;
@end

@implementation POMode
+ (instancetype)sharedInstance {
    static POMode* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

-(void)setMode:(NSString*)m {
  self->mode = m;
}

-(NSString*)mode {
  return self->mode;
}
@end

static int currentIndex = 0;
void runCommand(const char* command) {
  if(strcmp(command, "sbreload") == 0) {
    pid_t pid;
	  const char* args[] = {command, NULL};
	  posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char* const*)args, NULL);
  }
  if(strcmp(command, "safemode") == 0) {
    pid_t pid;
	  const char* args[] = {"killall", "-SEGV", "SpringBoard", NULL};
	  posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
  }
}
// iOS 13+
%group iOS13Hooks
%hook SBPowerDownViewController
-(void)viewWillAppear:(BOOL)arg1 {
  %orig;
  currentIndex = 0;
  [[POMode sharedInstance] setMode:@"SHUTDOWN"];
  SBPowerDownView *powerDownView = MSHookIvar<SBPowerDownView *>(self, "_powerDownView");
  _UIActionSlider *actionSlider = MSHookIvar<_UIActionSlider *>(powerDownView, "_actionSlider");
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:actionSlider action:@selector(knobTapped)];
  tap.numberOfTapsRequired = 1;
  UIView* knobView = [actionSlider _knobView];
  [knobView addGestureRecognizer:tap];
}
%end

%hook SBPowerDownView
-(void)_powerDownSliderDidCompleteSlide {
  if(![[POMode sharedInstance] mode] || [[[POMode sharedInstance] mode] isEqualToString:@"SHUTDOWN"])
    %orig;
  if([[[POMode sharedInstance] mode] isEqualToString:@"RESPRING"]) {
    if(access("/usr/bin/sbreload", F_OK) == 0)
      runCommand("sbreload");
    else
      [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
  }
  if([[[POMode sharedInstance] mode] isEqualToString:@"REBOOT"])
    [[%c(FBSystemService) sharedInstance] shutdownAndReboot:YES];
  if([[[POMode sharedInstance] mode] isEqualToString:@"SAFEMODE"])
    runCommand("safemode");
}
%end
%end

// iOS 12-
%group iOS12Hooks
%hook SBPowerDownController
- (void)activate {
  %orig;
  currentIndex = 0;
  [[POMode sharedInstance] setMode:@"SHUTDOWN"];
  SBPowerDownView *powerDownView = MSHookIvar<SBPowerDownView *>(self, "_powerDownView");
  UIView *internelView = MSHookIvar<UIView *>(powerDownView, "_internalView");
  _UIActionSlider *actionSlider = MSHookIvar<_UIActionSlider *>(internelView, "_actionSlider");
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:actionSlider action:@selector(knobTapped)];
  tap.numberOfTapsRequired = 1;
  UIView* knobView = [actionSlider _knobView];
  [knobView addGestureRecognizer:tap];
}

-(void)powerDown {
  if(![[POMode sharedInstance] mode] || [[[POMode sharedInstance] mode] isEqualToString:@"SHUTDOWN"])
    %orig;
  if([[[POMode sharedInstance] mode] isEqualToString:@"RESPRING"]) {
    if(access("/usr/bin/sbreload", F_OK) == 0)
      runCommand("sbreload");
    else
      [[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
  }
  if([[[POMode sharedInstance] mode] isEqualToString:@"REBOOT"])
    [[%c(FBSystemService) sharedInstance] shutdownAndReboot:YES];
  if([[[POMode sharedInstance] mode] isEqualToString:@"SAFEMODE"])
    runCommand("safemode");
}
%end
%end

%group Hooks
%hook _UIActionSlider
%new
- (UIImageView*)knobImageView
{
	return MSHookIvar<UIImageView*>(self, "_knobImageView");
}

%new
- (void)setColorKnobImage:(UIColor*)color
{
  UIImage* image = [self.knobImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self knobImageView].image = image;
  [self knobImageView].tintColor = color;
}

%new
-(void)knobTapped {
  currentIndex++;
  if(currentIndex > 3)
    currentIndex = 0;

  switch (currentIndex) {
    case 0:
      [self setTrackText:@"밀어서 전원 끄기"];
      [[POMode sharedInstance] setMode:@"SHUTDOWN"];
      [self setColorKnobImage: [UIColor redColor]];
      break;
    case 1:
      [self setTrackText:@"밀어서 리스프링"];
      [[POMode sharedInstance] setMode:@"RESPRING"];
      [self setColorKnobImage: [UIColor colorWithRed:131.0/255.0f green:126.0/255.0f blue:222.0/255.0f alpha:1.0f]];
      break;
    case 2:
      [self setTrackText:@"밀어서 재부팅"];
      [[POMode sharedInstance] setMode:@"REBOOT"];
      [self setColorKnobImage: [UIColor colorWithRed:81.0/255.0f green:156.0/255.0f blue:93.0/255.0f alpha:1.0f]];
      break;
    case 3:
      [self setTrackText:@"밀어서 안전모드"];
      [[POMode sharedInstance] setMode:@"SAFEMODE"];
      [self setColorKnobImage: [UIColor colorWithRed:253.0/255.0f green:180.0/255.0f blue:1.0/255.0f alpha:1.0f]];
      break;
  }
}
%end
%end


%ctor {
    if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
      %init(iOS13Hooks);
    else
      %init(iOS12Hooks);
    %init(Hooks);
}
