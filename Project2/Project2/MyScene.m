//
//  MyScene.m
//  Project2
//
//  Created by Student on 5/6/14.
//  Copyright (c) 2014 WEAREORGANIZED. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#import "GameOverScene.h"
#import "MenuView.h"

@import AVFoundation;

/*background Image: http://wall.alphacoders.com/big.php?i=414068 
 http://wallpaperbackgrounds.com/wallpaper/20608
 */




//these were used so commonly in the iOS games book we just c/p'd them here.
static inline CGPoint CGPointAdd(const CGPoint a,
                                 const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointSubtract(const CGPoint a,
                                      const CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a,
                                            const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

static inline CGFloat CGPointLength(const CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}

static inline CGPoint CGPointNormalize(const CGPoint a)
{
    CGFloat length = CGPointLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

static inline CGFloat CGPointToAngle(const CGPoint a)
{
    return atan2f(a.y, a.x);
}

static inline CGFloat ScalarSign(CGFloat a)
{
    return a >= 0 ? 1 : -1;
}

#define ARC4RANDOM_MAX      0x100000000
static inline CGFloat ScalarRandomRange(CGFloat min,
                                        CGFloat max)
{
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) *
                  (max - min) + min);
}

NSString *const kPlayer = @"harry1.png";
NSString *const kEnemy = @"worm1.png";


/*static uint32_t const kCategoryPlayer = 1;
static uint32_t const kCategoryWorm = 2;
static uint32_t const kCategoryTile = 4;*/

static uint32_t const kCategoryPlayerMask = 0x1 << 0;
static uint32_t const kCategoryEnemyMask = 0x1 << 1;
static uint32_t const kCategoryTileMask = 0x1 << 2;


static const float BG_POINTS=100;

int tileWidth, _tempNumTiles, onScreenTiles = 0;
int numWalls = 0;
int minNumTiles = 8;
int maxNumTiles = 20;
int playerScore = -1;

double _lastTime;
double _timeSinceLastSecondWentBy;

CGRect screenRect;
CGPoint jumpDestination, newDestination;
CGFloat previousPlayerYValue;
CGFloat nearestYValue;

@implementation MyScene
{
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    SKNode *_bglayer;
    SKNode *_tileLayer;
    CGFloat _screenWidth;
    CGFloat _screenHeight;
    SKSpriteNode *_player;
    SKSpriteNode *_walking;
    SKSpriteNode *_jumping;
    NSArray *_walkingFrames;
    NSArray *_jumpingFrames;
    SKAction *_moveToLeft;
    SKSpriteNode *_currentEnemy;
    SKSpriteNode *_enemy;
    SKSpriteNode *_wiggling;
    NSArray *_wigglingFrames;
    SKLabelNode *_playerScoreLabel;
    bool isWalking;
    int isJumping;
    
    AVAudioPlayer *_backgroundPlayer;
    AVAudioPlayer *_foleySoundPlayer;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        playerScore = 0;
        [self updateScoreLabel];
        
        onScreenTiles = 0;
        
        screenRect = self.scene.frame;
        _screenWidth = screenRect.size.width;
        _screenHeight = screenRect.size.height;
        
        //i want to see all the nodes, not just rendered ones
        [self.scene.view setValue:@(YES) forKey:@"_showsCulledNodesInNodeCount"];
        
        //set background node
        _bglayer=[SKNode node];
        [self addChild:_bglayer];
        
        //stuff node- where the meat and potatoes are.
        _tileLayer = [SKNode node];
        [self addChild:_tileLayer];
        
        _playerScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        _playerScoreLabel.fontSize = 30;
        _playerScoreLabel.position = CGPointMake(_screenWidth - 100, _screenHeight-90);
        _playerScoreLabel.text = @"Score: 0";
        [self addChild:_playerScoreLabel];
        
        //zero gravity
        //self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        //self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        _moveToLeft = [SKAction moveByX:-4 y:0 duration:0.1];

        for(int i =0; i<2;i++)
        {
            SKSpriteNode *bg= [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
            bg.anchorPoint = CGPointZero;
            bg.position = CGPointMake(i *bg.size.width, 0);
            bg.name =@"bg";
            [_bglayer addChild:bg];
            
            //look at chapter 5 page 136-141 for help about layers and correct positions of stuff
        }
        
        isWalking = true;
        [self spawnWalls:TRUE];
        [self setup:TRUE];
        
        [self playbgMusic:@"Loop.mp3"];
    }
    return self;
}

//i'm using this only to compare distance, so no need to square root it.
- (CGFloat) distance: (CGPoint) a : (CGPoint) b
{
    return ((a.x - b.x)*(a.x-b.x) + (a.y -b.y)*(a.y-b.y));
}

//touch logic
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    ++isJumping;
    
    if (isJumping <=1)
    {
        NSMutableArray *jumpingArray =[NSMutableArray array];
    
        SKTextureAtlas *jumpingAtles =[SKTextureAtlas atlasNamed:@"jumping"];
    
        int image = jumpingAtles.textureNames.count;
        for(int i=1; i<= image;i++)
        {
            NSString *textureName =[NSString stringWithFormat:@"jump%d",i];
            SKTexture *temp = [jumpingAtles textureNamed:textureName];
            [jumpingArray addObject:temp];
        }
        _jumpingFrames = jumpingArray;
        SKTexture *temp = _walkingFrames[0];
        _jumping = [SKSpriteNode spriteNodeWithTexture:temp];
        _jumping.position = CGPointMake(_walking.position.x, _walking.position.y);
        isWalking = false;
    
        [_tileLayer addChild:_jumping];
        [self jumpingPlayer];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    // calculate deltaTime
    
    /*if (isWalking) NSLog(@"Walking");
    else NSLog(@"Jumping");*/
    
    if (_walking.position.y < 0)
    {
        [self goToGameEnd];
    }
    
    double time = (double)CFAbsoluteTimeGetCurrent();
    
    float dt = time - _lastTime;
    _lastTime = time;
    
    _timeSinceLastSecondWentBy += dt;
    if(_timeSinceLastSecondWentBy > 1){
        _timeSinceLastSecondWentBy = 0;
        
        [self spawnEnemies: arc4random_uniform(5)];
        ++playerScore;
        [self updateScoreLabel];
    }
    
    __block CGFloat smallestDistance = CGFLOAT_MAX;
    //this will update each tile node and keep track of the number of tiles
    SKAction *removeFromParent = [SKAction removeFromParent];
    [_tileLayer enumerateChildNodesWithName:@"wall" usingBlock:^(SKNode *node, BOOL *stop)
     {
         CGFloat tempDistance = [self distance:node.position :_walking.position];
         if (tempDistance < smallestDistance)
         {
             nearestYValue = node.position.y;
             smallestDistance = tempDistance;
         }
         
         [node runAction: _moveToLeft];
            if (node.position.x < 0)
            {
                --onScreenTiles;
                [node runAction:removeFromParent];
            }
         if (onScreenTiles < 10 || onScreenTiles < 0)
         {
             [self spawnWalls:FALSE];
         }
     }];
    
    [self moveBG];
}
//moves the background and recycles it so it loops forever
-(void)moveBG
{
         CGPoint bgVelocity = CGPointMake(-BG_POINTS,0);
         CGPoint amtToMove= CGPointMultiplyScalar(bgVelocity, _dt);
         _bglayer.position = CGPointAdd(_bglayer.position,amtToMove);
         
         [_bglayer enumerateChildNodesWithName:@"bg" usingBlock:^(SKNode *node, BOOL *stop) {
             SKSpriteNode * bg = (SKSpriteNode *) node;
             CGPoint bgScreenPos = [_bglayer convertPoint:bg.position toNode:self];
             if (bgScreenPos.x <= -bg.size.width) {
                 bg.position = CGPointMake(bg.position.x + bg.size.width*2, bg.position.y);
             }
         }];
}

- (void)spawnWalls: (BOOL)firstTime
{
    if (firstTime)  NSLog(@"Spawning walls for first time");
    else     NSLog(@"Spawning walls for NOT the first time");
    _tempNumTiles = arc4random_uniform(maxNumTiles-minNumTiles) + minNumTiles;
    
    int randNumY= arc4random_uniform(2) + 1; //3 levels
    int xPosition;
    
    //if its the first time, spawn it on level 1 (380) otherwise randomize which level it's on
    int yPosition = firstTime ? 380 : (380 - ((randNumY-1) * 150));
    SKSpriteNode *wall;
    for (int i = 0; i < _tempNumTiles; i++)
    {
        wall = [SKSpriteNode spriteNodeWithImageNamed:@"wall"];
        wall.name = @"wall";
        wall.xScale = 2;
        wall.yScale = 1;
        xPosition = firstTime ? (i * wall.size.width) : ((i * wall.size.width) + _screenWidth) + (wall.size.width * 2);
        wall.position = CGPointMake(xPosition, yPosition);
        
        wall.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:wall.size];
        wall.physicsBody.usesPreciseCollisionDetection = YES;
        wall.physicsBody.dynamic = NO;
        wall.physicsBody.affectedByGravity = NO;
    
        //wall.physicsBody.categoryBitMask = kCategoryTileMask;
        //wall.physicsBody.contactTestBitMask = kCategoryPlayerMask;
        
        [_tileLayer addChild:wall];
        ++onScreenTiles;
    }
    tileWidth = wall.size.width;
    _tempNumTiles = 0;
}

-(void) spawnEnemies: (int) numEnemies
{
    CGPoint location;
    for (int i = 0; i < numEnemies; i++)
    {
        location = CGPointMake((arc4random_uniform(400) + _screenWidth),
                              arc4random_uniform(300) + 500);
        [self makeEnemy:location];
    }
}

-(void)makeEnemy: (CGPoint) location
{
    _enemy =[SKSpriteNode spriteNodeWithImageNamed:kEnemy];
    _enemy.position = location;
    _enemy.name = @"enemy";
    
    NSMutableArray *wigglingText =[NSMutableArray array];
    
    SKTextureAtlas *wormAtlas =[SKTextureAtlas atlasNamed:@"worm"];
    
    int image = wormAtlas.textureNames.count;
    for(int i=1; i<= image;i++)
    {
        NSString *textureName =[NSString stringWithFormat:@"worm%d",i];
        SKTexture *temp = [wormAtlas textureNamed:textureName];
        [wigglingText addObject:temp];
    }
    _wigglingFrames = wigglingText;
    SKTexture *temp = _wigglingFrames[0];
    _wiggling = [SKSpriteNode spriteNodeWithTexture:temp];
    _wiggling.position = location;
    
    SKAction *moveLeft = [SKAction moveByX:-24 y:0 duration:0.1];
    [_wiggling runAction:[SKAction repeatActionForever:moveLeft]];
    
    _wiggling.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_enemy.size];

    _wiggling.physicsBody.dynamic = YES;
    _wiggling.physicsBody.categoryBitMask = kCategoryEnemyMask;
    _wiggling.physicsBody.contactTestBitMask = kCategoryPlayerMask;
    //_wiggling.physicsBody.collisionBitMask = 0;
    _wiggling.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_tileLayer addChild:_wiggling];
    [self walkingEnemy];
}

-(void)setup: (BOOL) firstTime
{
    _player =[SKSpriteNode spriteNodeWithImageNamed:kPlayer];
   /* _player.position = CGPointMake(_screenWidth/4, _player.size.height/2);
    _player.zPosition =2;*/ //might need to add back in
    
    //[self addChild:_player];
    
    NSMutableArray *walkingText =[NSMutableArray array];
    
    SKTextureAtlas *walkingAtles =[SKTextureAtlas atlasNamed:@"sprite"];
    
    int image = walkingAtles.textureNames.count;
    for(int i=1; i<= image;i++)
    {
        NSString *textureName =[NSString stringWithFormat:@"harry%d",i];
        SKTexture *temp = [walkingAtles textureNamed:textureName];
        [walkingText addObject:temp];
    }
    _walkingFrames = walkingText;
    SKTexture *temp = _walkingFrames[0];
    _walking = [SKSpriteNode spriteNodeWithTexture:temp];
    
    if (firstTime) _walking.position = CGPointMake(screenRect.size.width/3,screenRect.size.height/2);
    else _walking.position = newDestination;
    
    _walking.physicsBody =[SKPhysicsBody bodyWithRectangleOfSize:_player.size];
    _walking.physicsBody.categoryBitMask = kCategoryPlayerMask;
    _walking.physicsBody.contactTestBitMask = kCategoryEnemyMask;// | kCategoryTileMask;
    _walking.physicsBody.dynamic = YES;
    _walking.physicsBody.collisionBitMask = kCategoryEnemyMask;// | kCategoryTileMask;
    _walking.physicsBody.usesPreciseCollisionDetection = YES;
    _walking.physicsBody.allowsRotation = FALSE;
    
    //NSLog(@"Starting to Walk");
    //jumpDestination = CGPointMake(_walking.position.x, _walking.position.y + 50);
    
    [_tileLayer addChild:_walking];
    [self walkingPlayer];
}

-(void)walkingPlayer
{
    isWalking = true;
    [_walking runAction:[SKAction repeatActionForever:
                         [SKAction animateWithTextures:_walkingFrames
                                          timePerFrame:0.1f
                                                resize:YES
                                               restore:YES]] withKey:@"WalkingPlayer"];
    return;
}

-(void)walkingEnemy
{
    [_wiggling runAction:[SKAction repeatActionForever:
                         [SKAction animateWithTextures:_wigglingFrames
                                          timePerFrame:0.1f
                                                resize:YES
                                               restore:YES]] withKey:@"WalkingEnemy"];
    return;
}

-(void)jumpingPlayer
{
    //NSLog([NSString stringWithFormat:@"_walking.position: %f,%f", _walking.position.x, _walking.position.y]);
    //NSLog([NSString stringWithFormat:@"Setting JumpDestination to %f,%f\nFrom position %f,%f", jumpDestination.x, jumpDestination.y, _walking.position.x, _walking.position.y]);
    jumpDestination = CGPointMake(_walking.position.x, _walking.position.y + 80);
    [_walking removeFromParent];
    isWalking =false;
    
    SKAction *animate =[SKAction animateWithTextures:_jumpingFrames
                                        timePerFrame:0.1f
                                              resize:YES restore:YES];
    SKAction *move = [SKAction moveToY:jumpDestination.y duration:0.20];
    
    SKAction *pause = [SKAction waitForDuration:0.2];
    
    SKAction *sink = [SKAction moveToY:nearestYValue + _walking.size.height + 15 duration:0.3];
    SKAction *remove = [SKAction removeFromParent];
    
    
    [_jumping runAction:[SKAction sequence:@[animate,move, pause, sink, remove]]];
    //isWalking = true;
    //if(isWalking)
    //{
    newDestination = _jumping.position;
    [self performSelector:@selector(redoWalking) withObject:self afterDelay:1.2];
        
    //}
    return;
}

-(void)redoWalking
{
    [self setup: FALSE];
    isJumping =0;
}


-(void)didSimulatePhysics {
    [self enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y < 0) [node removeFromParent];
    }];
}

-(void)updateScoreLabel
{
    if (playerScore < 0) playerScore = 0;
    _playerScoreLabel.text = [NSString stringWithFormat:@"Score: %d", playerScore];
}

-(void) didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if(contact.bodyA.categoryBitMask & kCategoryPlayerMask && contact.bodyA.categoryBitMask & kCategoryEnemyMask){
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    //NSLog([NSString stringWithFormat:@"isJumping Count: %d", isJumping]);
    //if neither of the colliding bodies are tiles
   if (((firstBody.categoryBitMask & kCategoryTileMask) == 0) &&
        ((secondBody.categoryBitMask & kCategoryTileMask) ==0))
    {
        //if first body is player and second is Enemy
        if (((firstBody.categoryBitMask & kCategoryPlayerMask) != 0) && ((secondBody.categoryBitMask & kCategoryEnemyMask) !=0))
        {
            NSLog(@"First body is player, second is enemy");
            if (!isWalking)
            {
                NSLog(@"Player is not walking");
                [secondBody.node removeFromParent];
                NSLog(@"Removing secondBody (enemy)");
                ++playerScore;
                [self playSound:@"enemyDying.mp3"];
                [self updateScoreLabel];
                return;
            }
            //[firstBody.node removeFromParent];
            //NSLog(@"aw u dead");
            else {
                NSLog(@"player IS walking and should die");
                [self playSound:@"moan.mp3"];
                [self goToGameEnd];
            }
        }
        else
        {
            NSLog(@"First body is enemy, second is player");
            if (isWalking)
            {
                NSLog(@"player is walking, you should die");
                [self playSound:@"moan.mp3"];
                [self goToGameEnd];
                return;
            }
            NSLog(@"Removing an enemy (first body) since player is not walking");
            [secondBody.node removeFromParent];
            ++playerScore;
            [self playSound:@"enemyDying.mp3"];
            [self updateScoreLabel];
        }
    }
    else
    {
        
    }
}

-(void)playbgMusic:(NSString *)filename
{
    NSError *error;
    NSURL *backgroundURL =[[NSBundle mainBundle]URLForResource:filename withExtension:nil];
    _backgroundPlayer =[[AVAudioPlayer alloc]initWithContentsOfURL:backgroundURL error:&error];
    _backgroundPlayer.numberOfLoops =-1;
    [_backgroundPlayer prepareToPlay];
    [_backgroundPlayer play];
}
-(void)playSound:(NSString *)filename
{
    NSError *error;
    NSURL *backgroundURL =[[NSBundle mainBundle]URLForResource:filename withExtension:nil];
    _foleySoundPlayer =[[AVAudioPlayer alloc]initWithContentsOfURL:backgroundURL error:&error];
    _foleySoundPlayer.numberOfLoops =1;
    [_foleySoundPlayer prepareToPlay];
    [_foleySoundPlayer play];
}

-(void) goToGameEnd
{
    SKScene *gameEnd = [[GameOverScene alloc] initWithSize:screenRect.size];
    
    [self.view presentScene:gameEnd];
}

@end
