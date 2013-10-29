//
//  GameLevelLayer.m
//  Dance Wars
//
//  Created by Prayaas Jain on 9/20/13.
//  Copyright 2013 Ameya Koshti. All rights reserved.
//

#import "AppDelegate.h"
#import "GameLevelLayer.h"

@implementation GameLevelLayer

@synthesize life,aiLife,progressTimer,aiProgressTimer,background;

static NSString * const UIGestureRecognizerNodeKey = @"UIGestureRecognizerNodeKey";

// Time between the touch icons
static float levelDifficulty1Speed = 1.50;
static float levelDifficulty2Speed = 1.00;
static float levelDifficulty3Speed = 0.75;
static float speed;
static float swipeSpeed = 2.0;

+(CCScene *) scene{
	CCScene *scene = [CCScene node];
	GameLevelLayer *layer = [GameLevelLayer node];
	[scene addChild: layer];
	return scene;
}

-(id) init {
    
    if((self = [super init])) {
        
        size = [[CCDirector sharedDirector] winSize];
        
        // Loading game environment
        sharedManager = [MyManager sharedManager];
        le = [sharedManager.inputBundle objectForKey:@"ENVR"];
        le.background.position = ccp(size.width/2, size.height/2);
        [self addChild:le.background z:-10];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:le.backgroundMusic];
        [self performSelector:@selector(initiateBackground:) withObject:le.backgroundName afterDelay:0.75];

        // Get character selected values from the character selection screen
        charHand = [sharedManager.inputBundle objectForKey:@"ch"];
        
        // Player character
        dancer = [CCSprite spriteWithFile:[charHand.charName stringByAppendingString:@"_0.png"]];
        dancer.position = ccp(150,200);
        [self addChild:dancer z:0 tag:1];
        
        // AI character
        aichar = [CCSprite spriteWithFile:@"dance1.png"];
        aichar.position = ccp(876,230);
        [self addChild:aichar z:0 tag:2];
       
        // Player life bar
        self.life = 0;
        self.progressTimer = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"healthbar_red.png"]];
        self.progressTimer.type = kCCProgressTimerTypeBar;
        self.progressTimer.midpoint = ccp(0,0);
        self.progressTimer.barChangeRate = ccp(1,0);
        [self.progressTimer setScale:1];
        self.progressTimer.percentage = self.life;
        self.progressTimer.position = ccp(120 ,size.height-50);
        [self addChild:self.progressTimer];        

        // AI life bar
        self.aiLife = 0;
        self.aiProgressTimer = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"healthbar_red.png"]];
        self.aiProgressTimer.type = kCCProgressTimerTypeBar;
        self.aiProgressTimer.midpoint = ccp(0,0);
        self.aiProgressTimer.barChangeRate = ccp(1,0);
        [self.aiProgressTimer setScale:1];
        self.aiProgressTimer.percentage = self.aiLife;
        self.aiProgressTimer.position = ccp(size.width-120,size.height-50);
        [self addChild:self.aiProgressTimer];
        
        // Displaying a home button to return to the main menu screen
        CCMenuItemImage *homeButton = [CCMenuItemImage itemWithNormalImage:@"home.png" selectedImage:@"home_pressed.png" target:self selector:@selector(loadHelloWorldLayer)];
        CCMenu *homeMenu = [CCMenu menuWithItems:homeButton, nil];
        homeMenu.position = ccp(size.width-homeButton.contentSize.width/2, homeButton.contentSize.height/2);
        [self addChild:homeMenu];
        
        // Start the game by showing the touch icons
        touchPointCounter=1;
        totalGeneratedObjects = 0;
        [self manageTouchIcons];
        
        // Enable multi touches and gestures
        self.touchEnabled = YES;
        [[[CCDirector sharedDirector]view]setMultipleTouchEnabled:YES];

        // Input handler object initialization to set the speed of the touch icons
        ih = [sharedManager.inputBundle objectForKey:@"LDAA"];
        switch (ih.gameLevelDifficulty)
        {
            case 1:
                speed = levelDifficulty1Speed;
                break;
            case 2:
                speed = levelDifficulty2Speed;
                break;
            case 3:
                speed = levelDifficulty3Speed;
                break;
        }
        
        // Initial idle move for user
        //[self initiateIdleDance];
    }
    
    return self;
}

-(void) addMessage:(NSString *)image{
    message = [CCSprite spriteWithFile:image];
    if([image isEqualToString:@"danceMessage.png"]){
        message.position = ccp(size.width/2,size.height/2);
    }
    if([image isEqualToString:@"nice.png"]){
        message.position = ccp(size.width/2,size.height*2/3);
    }
    if([image isEqualToString:@"youwin.png"]){
        message.position = ccp(size.width/2,size.height*2/3);
    }
    if([image isEqualToString:@"youlose.png"]){
        message.position = ccp(size.width/2,size.height*2/3);
    }
    [self addChild:message];
}

-(void) removeMessage{
    [self removeChild:message cleanup:YES];
}

-(void) gamePlayLoopCondition {
    
    if (self.life<100 && self.aiLife<100) {
        objectCount=0;
        touchPointCounter=1;
        
        [self addMessage:@"danceMessage.png"];
        [self performSelector:@selector(removeMessage) withObject:[NSNumber numberWithInt:1] afterDelay:1];
        //[self schedule:@selector(manageTouchIcons) interval:1.0 repeat:1 delay:1.5];
        [self manageTouchIcons];
    }
    else {
        [self scheduleOnce:@selector(initiateBlast) delay:1.0];
        
        if(self.life > self.aiLife){
            [self addMessage:@"youwin.png"];
            [self performSelector:@selector(removeMessage) withObject:[NSNumber numberWithInt:1] afterDelay:3.5];
            [self removeChild:backgroundSpriteSheet];
        }
        else{
            [self addMessage:@"youlose.png"];
            [self performSelector:@selector(removeMessage) withObject:[NSNumber numberWithInt:1] afterDelay:3.5];
            [self removeChild:backgroundSpriteSheet];
        }
    }
    
}

-(void) initiateBackground:(NSString *)dynamicBackground
{
    NSLog(@"background value is %@",dynamicBackground);
    NSString *background_plist = [dynamicBackground stringByAppendingString:@".plist"] ;
    NSString *background_spriteList = [dynamicBackground stringByAppendingString:@".png"];
    
    [self removeChild:backgroundSpriteSheet cleanup:YES];
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile: background_plist];
    backgroundSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:background_spriteList];
    NSMutableArray *backgroundFrames = [NSMutableArray array];
    
    for (int i=1; i < 13; i++)
    {
        NSString *lastPart = [NSString stringWithFormat:@"_%d.png",i];
        NSString *animation_name = [dynamicBackground stringByAppendingString:lastPart];
        [backgroundFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:animation_name]];
    }
    
    CCAnimation *backgroundDuration = [CCAnimation animationWithSpriteFrames:backgroundFrames delay:0.1f];
    NSString *frameName = [dynamicBackground stringByAppendingString:@"_1.png"];
    CCSprite *backgroundSprite = [CCSprite spriteWithSpriteFrameName:frameName];
    backgroundSprite.position = ccp(size.width/2, size.height/2);
    CCAction *backgroundAction = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:backgroundDuration]];
    
    [backgroundSprite runAction:backgroundAction];
    [backgroundSpriteSheet addChild:backgroundSprite];
    [self addChild:backgroundSpriteSheet z:-10];
}

-(void) initiateIdleDance {
    NSString *danceMove = @"_i";
    NSString *player = [charHand.charName stringByAppendingString:danceMove];
    NSString *player_plist = [player stringByAppendingString:@".plist"] ;
    NSString *player_spriteList = [player stringByAppendingString:@".png"];
    
    [self removeChildByTag:1 cleanup:YES];
    [self removeChild:userSpriteSheet cleanup:YES];
    
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile: player_plist];
    userSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:player_spriteList];
    
    NSMutableArray *danceFrames = [NSMutableArray array];
    
    for (int i=1; i <= 63; i++) {
        NSString *lastPart = [NSString stringWithFormat:@"_%d.png",i];
        NSString *animation_name = [ player stringByAppendingString:lastPart];
        [danceFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:animation_name]];
    }
    
    CCAnimation *danceDuration = [CCAnimation animationWithSpriteFrames:danceFrames delay:0.1f];
    
    NSString *frameName = [player stringByAppendingString:@"_1.png"];
    CCSprite *dance = [CCSprite spriteWithSpriteFrameName:frameName];
    dance.position = ccp(150,200);
    CCFiniteTimeAction *danceAction = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:danceDuration] times:1];
    
    [dance runAction:[CCSequence actions: danceAction, [CCCallFunc actionWithTarget:self selector:@selector(initiateAIDance)],nil]];
    [userSpriteSheet addChild:dance];
    [self addChild:userSpriteSheet];
}

-(void) initiateUserDance:(NSString *)danceMove{
    NSString *player = [charHand.charName stringByAppendingString:danceMove];
    
    // Count the number of frames from the plist
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:player ofType:@"plist"];
    NSDictionary *Dictionary= [[NSDictionary alloc]initWithContentsOfFile:plistPath];
    int numberOfFrames = [[Dictionary valueForKey:@"frames"] count];

    if(numberOfFrames > 0){
        // Remove previous player sprite and add the new dance sprite
        [self removeChildByTag:1 cleanup:YES];
        [self removeChild:userSpriteSheet cleanup:YES];
        
        NSString *player_plist = [player stringByAppendingString:@".plist"] ;
        NSString *player_spriteList = [player stringByAppendingString:@".png"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile: player_plist];
        userSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:player_spriteList];
        
        NSMutableArray *danceFrames = [NSMutableArray array];
        
        for (int i=1; i <= numberOfFrames; i++) {
            NSString *lastPart = [NSString stringWithFormat:@"_%d.png",i];
            NSString *animation_name = [ player stringByAppendingString:lastPart];
            [danceFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:animation_name]];
        }
        
        CCAnimation *danceDuration = [CCAnimation animationWithSpriteFrames:danceFrames delay:0.1f];
        
        NSString *frameName = [player stringByAppendingString:@"_1.png"];
        CCSprite *dance = [CCSprite spriteWithSpriteFrameName:frameName];
        dance.position = ccp(150,200);
        CCFiniteTimeAction *danceAction = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:danceDuration] times:1];
        
        [dance runAction:[CCSequence actions: danceAction, [CCCallFunc actionWithTarget:self selector:@selector(initiateAIDance)],nil]];
        [userSpriteSheet addChild:dance];
        [self addChild:userSpriteSheet];
    }
    else{
        [self initiateAIDance];
    }
}

-(void) initiateAIDance {
    
    [self removeChildByTag:2 cleanup:YES];
    [self removeChild:aiSpriteSheet cleanup:YES];
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"dance.plist"];
    aiSpriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"dance.png"];
    
    NSMutableArray *walkframes = [NSMutableArray array];
    
    for (int j = 1; j <= 2; j++) {
        for (int i = 1; i <= 10; ++i) {
            NSString *frameName = [NSString stringWithFormat:@"dance%d.png",i];
            [walkframes addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:frameName]];
        }
    }
    
    CCAnimation *walk = [CCAnimation animationWithSpriteFrames:walkframes delay:0.1f];
    CCSprite *dance = [CCSprite spriteWithSpriteFrameName:@"dance1.png"];
    dance.position = ccp(876, 200);
    
    CCAction *danceAction = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:walk] times:1];
    
    [dance runAction:danceAction];
    [aiSpriteSheet addChild:dance];
    [self addChild:aiSpriteSheet];
    
    [self scheduleOnce:@selector(gamePlayLoopCondition) delay:0.5];
    
    // this is to get the score for the AI player
    int aiscore = (int)(([getScore calScore]*100)/2100);
    
    // update AI progress bar
    if(self.aiLife >= 0 && self.aiLife < 100){
        self.aiLife += aiscore;
        if(self.aiLife > 25 && self.aiLife < 60){
            [self.aiProgressTimer setSprite:[CCSprite spriteWithFile:@"healthbar_orange.png"]];
            [self.aiProgressTimer setScale:1];
        }
        if(self.aiLife > 60){
            [self.aiProgressTimer setSprite:[CCSprite spriteWithFile:@"healthbar_green.png"]];
            [self.aiProgressTimer setScale:1];
        }
        if(self.aiLife < 25){
            [self.aiProgressTimer setSprite:[CCSprite spriteWithFile:@"healthbar_red.png"]];
            [self.aiProgressTimer setScale:1];
        }
    }
    [self.aiProgressTimer setPercentage:self.aiLife];
}

-(void) initiateBlast {
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"bomb.plist"];
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"bomb.png"];
    
    NSMutableArray *walkframes = [NSMutableArray array];
    
    for (int i = 1; i <= 21; ++i) {
        NSString *frameName = [NSString stringWithFormat:@"f%d.png",i];
        [walkframes addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:frameName]];
    }
    
    CCAnimation *walk = [CCAnimation animationWithSpriteFrames:walkframes delay:0.1f];
    CCSprite *blast = [CCSprite spriteWithSpriteFrameName:@"f1.png"];
    if(self.life > self.aiLife){
        blast.position = ccp(876, 250);
    }
    else{
        blast.position = ccp(150, 250);
    }
    
    CCAction *blastAction = [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:walk] times:1];
    
    [blast runAction:blastAction];
    [spriteSheet addChild:blast];
    [self addChild:spriteSheet];
}

-(void) loadHelloWorldLayer {
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background.mp3"];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:0.2 scene:[HelloWorldLayer scene]]];
}

-(void) manageTouchIcons {
    // Setting move difficulty
    NSString *moveDifficulty;
    InputHandler *ihMoveDiff = [sharedManager.inputBundle objectForKey:@"USERLIFE+MOVEDIFF"];
    if ([ihMoveDiff moveDifficulty] == 0){
        moveDifficulty = @"MoveDifficultyWt3";
    }
    else{
        moveDifficulty = [NSString stringWithFormat:@"MoveDifficultyWt%d",[ihMoveDiff moveDifficulty]];
    }
    
    // Reading from pList
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"TouchPatterns" ofType:@"plist"];
    NSDictionary *Dictionary = [[NSDictionary alloc]initWithContentsOfFile:plistPath];
    
    // Reading move difficulties from pList
    NSDictionary *DictionaryMoveDifficulty = [Dictionary valueForKey:moveDifficulty];

    // Number of patterns in the current move difficulty
    int numberOfPatterns = [[Dictionary valueForKey:moveDifficulty] count];
    
    // Randomly select a pattern
    int lowerBound = 1;
    int upperBound = numberOfPatterns;
    int randomPattern = lowerBound + arc4random() % (upperBound - lowerBound);
    
    // Reading touch pattern from pList based on the randomly selected move
    NSDictionary *DictionaryMove = [DictionaryMoveDifficulty valueForKey:[NSString stringWithFormat:@"Move%d",randomPattern]];
    
    // Everytime allocate to avoid overlap
    singleTouches = [[NSArray alloc]init];
    doubleTouches = [[NSArray alloc]init];
    swipes = [[NSArray alloc]init];
    
    singleTouches = [[DictionaryMove valueForKey:@"SingleTouches"] componentsSeparatedByString:@","];
    doubleTouches = [[DictionaryMove valueForKey:@"DoubleTouches"] componentsSeparatedByString:@","];
    swipes = [[DictionaryMove valueForKey:@"Swipes"] componentsSeparatedByString:@","];
    
    totalGeneratedObjects = (singleTouches.count) + (doubleTouches.count*2) + (swipes.count*2);
    
    [self schedule:@selector(displayTouchIcons) interval:2.1 repeat:5 delay:1.5];
}

-(void) displayTouchIcons {
    // to check if both the touch icons are tapped at the same time
    visited[1] = 0;
    visited[2] = 0;
    
    swipeHit = NO;
    
    // touchpointcounter starts with 0 and the Touches array start from 1, hence touchPointCounter+1
    for (int i = 0 ; i < singleTouches.count ; i++){
        if([singleTouches[i] intValue] == (touchPointCounter)){
            [self addTouchIcons:1 withArg2:@"touchpoints.png" withArg3:NO];
            [self performSelector:@selector(removeTouchIcons:) withObject:[NSNumber numberWithInt:1] afterDelay:speed];
            break;
        }
    }
   
    for (int i = 0 ; i < doubleTouches.count ; i++){
        if([doubleTouches[i] intValue] == (touchPointCounter)){
            [self addTouchIcons:1 withArg2:@"touchpoints-blue.png" withArg3:NO];
            [self performSelector:@selector(removeTouchIcons:) withObject:[NSNumber numberWithInt:1] afterDelay:speed];
            
            [self addTouchIcons:2 withArg2:@"touchpoints-blue.png" withArg3:NO];
            [self performSelector:@selector(removeTouchIcons:) withObject:[NSNumber numberWithInt:2] afterDelay:speed];
            break;
        }
    }
    
    for (int i = 0 ; i < swipes.count ; i++){
        if([swipes[i] intValue] == (touchPointCounter)){
            [self addTouchIcons:1 withArg2:@"touchpoints-green.png" withArg3:YES];
            [self performSelector:@selector(removeTouchIcons:) withObject:[NSNumber numberWithInt:1] afterDelay:swipeSpeed];
            
            [self addTouchIcons:2 withArg2:@"touchpoints-blue.png" withArg3:YES];
            [self performSelector:@selector(removeTouchIcons:) withObject:[NSNumber numberWithInt:2] afterDelay:swipeSpeed];
            break;
        }
    }
    
    // This is counter is for counting the number of times the touch icons will appear
    // It does not count the total number of touch icons.
    touchPointCounter++;

}

-(void) addTouchIcons:(int) touchNumber withArg2:(NSString *) fileName withArg3:(BOOL) swipeEnable {
    touchIcon[touchNumber] = [CCSprite spriteWithFile:fileName];

    // creating the imaginary rectangle in which the icons will appear
    float randomH,randomW;
    float maxX = size.width * 2/3;
    float minX = size.width * 1/3;
    float maxY = size.height * 2/3;
    float minY = size.height * 1/3;
    float rangeX = maxX - minX;
    float rangeY = maxY - minY;
    
    // Show the first touch icon randomly
    if(objectCount == 0){
        randomH = (arc4random() % (int)rangeY) + (int)minY;
        randomW = (arc4random() % (int)rangeX) + (int)minX;
    }
    else{
        int halfOfTouchIcon = touchIcon[touchNumber].contentSize.width/2;
        float previousRangeXFrom = xLocations[objectCount-1]-halfOfTouchIcon;
        float previousRangeXTo = xLocations[objectCount-1]+halfOfTouchIcon;
        float previousRangeYFrom = yLocations[objectCount-1]-halfOfTouchIcon;
        float previousRangeYTo = yLocations[objectCount-1]+halfOfTouchIcon;
        
        while(1){
            randomH = (arc4random() % (int)rangeY) + (int)minY;
            randomW = (arc4random() % (int)rangeX) + (int)minX;
            
            if((randomW < previousRangeXFrom || randomW > previousRangeXTo) && (randomH < previousRangeYFrom || randomH > previousRangeYTo)){
                break;
            }
        }
    }
    touchIcon[touchNumber].position = ccp(randomW, randomH);
    
    // these variables are used to store the location of the touch points to calculate the score
    xLocations[objectCount] = (float)randomW;
    yLocations[objectCount] = (float)randomH;
    
    // This is to enable swipe gesture on touch icon
    if(swipeEnable){
        touchIcon[touchNumber].isTouchEnabled = YES;
        [self enableGesture:[NSNumber numberWithInt:touchNumber]];
    }else{
        [self addChild:touchIcon[touchNumber]];
    }
    
    // Counts the number of objects in every round
    objectCount ++;
    
    // The total number of objects across all the round
    totalObjects ++;
    
    // Some animation where the icon is generated
    CCParticleSystem *emitter = [CCParticleExplosion node];
    //set the location of the emitter
    emitter.position = touchIcon[touchNumber].position;
    //set size of particle animation
    emitter.scale = 0.5;
    //set an Image for the particle
    emitter.texture = [[CCTextureCache sharedTextureCache] addImage:@"touchpoints.png"];
    //set length of particle animation
    [emitter setLife:0.1f];
    //add to layer ofcourse(effect begins after this step)
    [self addChild: emitter];
}

-(void) removeTouchIcons:(NSNumber *) value{
    int val = [value intValue];
    [self removeChild:touchIcon[val] cleanup:YES];
    
    if(objectCount == totalGeneratedObjects){
        
        // Calculate the score and accuracy for user and ai
        InputHandler *ih2 = [sharedManager.inputBundle objectForKey:@"LDAA"];
        
        [ih2 setUserAccuracy:(hitCount*100/objectCount)];
        [sharedManager.inputBundle setObject:ih2 forKey:@"USERACC"];
        
        getScore = [[Score alloc] init];
        [getScore calScore];
        
        [self updateUserProgressBar];
    }
}

-(void) updateUserProgressBar {
    
    InputHandler *ih3 = [sharedManager.inputBundle objectForKey:@"USERLIFE+MOVEDIFF"];
    
    // Increment progress bar for user
    if(self.life >= 0 && self.life < 100){
        self.life += (int)[ih3 userLife];
        if(self.life > 25 && self.life < 60){
            [self.progressTimer setSprite:[CCSprite spriteWithFile:@"healthbar_orange.png"]];
            [self.progressTimer setScale:1];
        }
        if(self.life > 60){
            [self.progressTimer setSprite:[CCSprite spriteWithFile:@"healthbar_green.png"]];
            [self.progressTimer setScale:1];
        }
    }
    [self.progressTimer setPercentage:self.life];
    
    // Enable dance show for Player
    [self initiateUserDance:@"_d1"];

}

-(void) enableGesture:(NSNumber *) value{
    // pan gesture recognizer
    UIGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGestureRecognizer.delegate = self;
    [touchIcon[[value intValue]] addGestureRecognizer:panGestureRecognizer];
    [self addChild:touchIcon[[value intValue]]];
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

-(void) handlePanGesture:(UIPanGestureRecognizer*)aPanGestureRecognizer{
    CCNode *node = aPanGestureRecognizer.node;
    CGPoint translation = [aPanGestureRecognizer translationInView:aPanGestureRecognizer.view];
    translation.y *= -1;
    [aPanGestureRecognizer setTranslation:CGPointZero inView:aPanGestureRecognizer.view];
    
    node.position = ccpAdd(node.position, translation);
    
    // this is to check if the touch gesture has been through the other point
        
    if(CGRectContainsPoint(touchIcon[1].boundingBox, ccp(touchIcon[2].position.x,touchIcon[2].position.y)) && !swipeHit){
        swipeHit = YES;
        
        // Particle effects on a gesture hit
        CCParticleSystem *emitterGesture = [CCParticleExplosion node];
        emitterGesture.position = node.position;
        emitterGesture.scale = 0.5;
        emitterGesture.texture = [[CCTextureCache sharedTextureCache] addImage:@"Icon-Small.png"];
        [emitterGesture setLife:1.0f];
        [self addChild: emitterGesture];
        
        if(self.life >= 0 && self.life < 100){
            self.life += 1;
            if(self.life > 25 && self.life < 60){
                [self.progressTimer setSprite:[CCSprite spriteWithFile:@"healthbar_orange.png"]];
                [self.progressTimer setScale:1];
            }
            if(self.life > 60){
                [self.progressTimer setSprite:[CCSprite spriteWithFile:@"healthbar_green.png"]];
                [self.progressTimer setScale:1];
            }
        }
       [self.progressTimer setPercentage:self.life];
    }
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    // Check for taps only when its not the 6th tap
    // 6th tap is gesture based
    if(touchPointCounter !=5 ){
        for(UITouch *touch in touches)
        {
            CGPoint location = [[CCDirector sharedDirector] convertTouchToGL:touch];
            
            if((CGRectContainsPoint(touchIcon[1].boundingBox, location))) {
                visited[1] = 1;
                hitCount++;
            }
            if((CGRectContainsPoint(touchIcon[2].boundingBox, location))) {
                visited[2] = 1;
                hitCount++;
            }
            else {
               // for negative points
            }
        }
        
        //checkIfBothHit = 0;
        if(visited[1] == 1 && visited[2] == 1){
            [self addMessage:@"nice.png"];
            [self performSelector:@selector(removeMessage) withObject:[NSNumber numberWithInt:1] afterDelay:0.5];
        }
    }
}

-(void) dealloc {

}

@end
