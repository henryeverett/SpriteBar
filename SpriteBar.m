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

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval timerInterval;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, strong) id timerTarget;
@property (nonatomic, assign) SEL timerSelector;

/* Called upon timer interval. */
- (void)timerTick:(NSTimer *)timer;
/* Calculate the number of frames in the texture atlas. */
- (NSInteger)numberOfFramesInAnimation:(NSString *)animationName;

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
        [self resetProgress];
    }
    return self;
}

- (void)resetProgress {
    
    [self invalidateTimer];
    self.currentTime = 0;
    self.texture = [self.atlas textureNamed:[NSString stringWithFormat:@"%@_0.png",self.textureReference]];
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
    CGFloat percent = progress * 100;
    self.texture = [self.atlas textureNamed:[NSString stringWithFormat:@"%@_%lu.png",self.textureReference,lrint(percent)]];
    
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

@end
