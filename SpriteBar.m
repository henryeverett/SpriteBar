//
//  SpriteBar.m
//  SpriteBar
//
//  Created by Henry Everett on 27/05/2014.
//  Copyright (c) 2014 Henry Everett. All rights reserved.
//

#import "SpriteBar.h"

@interface SpriteBar ()

@property (nonatomic, strong) SKTextureAtlas *atlas;
@property (nonatomic, strong) NSMutableArray *availableTextureAddresses;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval timerInterval;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, strong) id timerTarget;
@property (nonatomic, assign) SEL timerSelector;

/* Called upon timer interval. */
- (void)timerTick:(NSTimer *)timer;
/* Calculate the number of frames in the texture atlas. */
- (NSInteger)numberOfFramesInAnimation:(NSString *)animationName;
/* Find the nearest texture number to a given percent. */
- (NSInteger)closestAvailableToPercent:(NSInteger)percent;
/* Extract the percent identifier from a texture name. */
- (NSNumber *)percentFromTextureName:(NSString *)string;

@end

@implementation SpriteBar

@synthesize atlas;

- (id)init {
    
    SKTextureAtlas *defaultAtlas = [SKTextureAtlas atlasNamed:@"sb_default"];
    
    return [self initWithTextureAtlas:defaultAtlas];
}

- (id)initWithTextureAtlas:(SKTextureAtlas *)textureAtlas {
    
    self = [super init];
    if (self) {
        self.atlas = textureAtlas;
        self.textureReference = @"progress";
    }
    return self;
}

- (void)resetProgress {
    
    self.texture = [self.atlas textureNamed:[NSString stringWithFormat:@"%@_%lu.png",self.textureReference,[self closestAvailableToPercent:0]]];
    
    self.availableTextureAddresses = [[NSMutableArray alloc] init];
    
    for (NSString *name in self.atlas.textureNames) {
        [self.availableTextureAddresses addObject:[self percentFromTextureName:name]];
    }

    [self invalidateTimer];
    // Set defaults
    self.currentTime = 0;
    
}

- (void)startBarProgressWithTimer:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector {
    
    [self resetProgress];
    
    self.timerTarget = target;
    self.timerSelector = selector;
    
    // Split the progress time between animation frames
    self.timerInterval = seconds / ([self numberOfFramesInAnimation:self.textureReference] - 1);
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timerInterval target:self selector:@selector(timerTick:) userInfo:[NSNumber numberWithDouble:seconds] repeats:YES];
    
}

- (void)timerTick:(NSTimer *)timer {
    
    // Increment timer interval counter
    self.currentTime += self.timerInterval;
    
    // Make sure we don't exceed the total time
    if (self.currentTime <= [timer.userInfo doubleValue]) {
        [self setProgressWithValue:self.currentTime ofTotal:[timer.userInfo doubleValue]];
    }
}

- (void)invalidateTimer {
    [self.timer invalidate];
}

- (void)setProgressWithValue:(CGFloat)progress ofTotal:(CGFloat)maxValue {
    
    [self setProgress:progress/maxValue];

}

- (void)setProgress:(CGFloat)progress {
    
    // Set texure
    CGFloat percent = lrint(progress * 100);
    
    self.texture = [self.atlas
                    textureNamed:[NSString stringWithFormat:@"%@_%lu.png",self.textureReference,[self closestAvailableToPercent:percent]]];
    
    // If we have reached 100%, invalidate the timer and perform selector on passed in object.
    if (fabsf(progress) >= fabsf(1.0)) {
        
        if (self.timerTarget && [self.timerTarget respondsToSelector:self.timerSelector]) {
            
            IMP imp = [self.timerTarget methodForSelector:self.timerSelector];
            void (*func)(id, SEL) = (void *)imp;
            func(self.timerTarget, self.timerSelector);
        }
    
        [self.timer invalidate];
    }

}

- (NSInteger)numberOfFramesInAnimation:(NSString *)animationName {
    // Get the number of frames in the animation.
    NSArray *allAnimationNames = self.atlas.textureNames;
    NSPredicate *nameFilter = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@",animationName];
    return [[allAnimationNames filteredArrayUsingPredicate:nameFilter] count];
}

- (NSInteger)closestAvailableToPercent:(NSInteger)percent {

    NSInteger closest = 0;
    
    for (NSNumber *thisPerc in self.availableTextureAddresses) {
        if (labs(thisPerc.integerValue - percent) < labs(closest - percent)) {
            closest = thisPerc.integerValue;
        }
    }

    return closest;
}

- (NSNumber *)percentFromTextureName:(NSString *)string {
    
    // Get rid of "@2x"
    NSString *clippedString = [string stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
    
    // Match the rest of the pattern
    NSString *pattern = [NSString stringWithFormat:@"(?<=%@_)([0-9]+)(?=.png)",self.textureReference];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *matches = [regex matchesInString:clippedString options:0 range:NSMakeRange(0, clippedString.length)];
    
    // If the matches don't equal 1, you have done something wrong.
    if (matches.count != 1) {
        [NSException raise:@"SpriteBar: Incorrect texture naming."
                    format:@"Textures should follow naming convention: %@_#.png. Failed texture name: %@",self.textureReference,string];
    }
    
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        return [NSNumber numberWithInteger:[[clippedString substringWithRange:matchRange] integerValue]];
    }
    
    return nil;
}

@end
