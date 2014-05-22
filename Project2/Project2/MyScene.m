//
//  MyScene.m
//  Project2
//
//  Created by Student on 5/6/14.
//  Copyright (c) 2014 WEAREORGANIZED. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"
#import <AVFoundation/AVFoundation.h>

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


static uint32_t const kCategoryPlayer = 1;
static uint32_t const kCategoryWorm = 2;
static uint32_t const kCategoryTile = 4;


static const float BG_POINTS=100;

int tileWidth, _tempNumTiles, onScreenTiles = 0;
int numWalls = 0;
int minNumTiles = 8;
int maxNumTiles = 20;
int playerScore = -1;

double _lastTime;
double _timeSinceLastSecondWentBy;

CGRect screenRect;

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
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
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
        [self setup];
        [self spawnEnemies:1];
    }
    return self;
}

//touch logic
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
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
    //_walking.position = CGPointMake(100, 100);
    
    isWalking = false;
    
    [self addChild:_jumping];
    [self jumpingPlayer];
    [self runAction:[SKAction sequence:@[]]];   //might remove- corey doesn't have- will see what happens
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    // calculate deltaTime
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
    
    //this will update each tile node and keep track of the number of tiles
    SKAction *removeFromParent = [SKAction removeFromParent];
    [_tileLayer enumerateChildNodesWithName:@"wall" usingBlock:^(SKNode *node, BOOL *stop)
     {
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
        xPosition = firstTime ? (i * wall.size.width) + _screenWidth - 100 : ((i * wall.size.width) + _screenWidth) + (wall.size.width * 2);
        wall.position = CGPointMake(xPosition, yPosition);
        wall.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:wall.size];
        wall.physicsBody.usesPreciseCollisionDetection = YES;
        [_tileLayer addChild:wall];
        wall.physicsBody.affectedByGravity = NO;
        wall.physicsBody.dynamic = NO;
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
    NSLog([NSString stringWithFormat:@"Location of enemy: %f,%f", location.x, location.y]);
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
    _wiggling.physicsBody.usesPreciseCollisionDetection = YES;
    
    [_tileLayer addChild:_wiggling];
    [self walkingEnemy];
}

-(void)setup
{
    /*_player =[SKSpriteNode spriteNodeWithImageNamed:kPlayer];
    _player.position = CGPointMake(_screenWidth/4, _player.size.height/2);
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
    _walking.position = CGPointMake(screenRect.size.width/3,screenRect.size.height/2);
    
    _walking.physicsBody =[SKPhysicsBody bodyWithRectangleOfSize:_player.size];
    _walking.physicsBody.dynamic = YES;
    _walking.physicsBody.categoryBitMask = kCategoryPlayer;
    _walking.physicsBody.contactTestBitMask = kCategoryTile;
    _walking.physicsBody.collisionBitMask = 0;
    //_walking.position = CGPointMake(100, 100);
    
    [self addChild:_walking];
    [self walkingPlayer];
}

-(void)walkingPlayer
{
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
    [_walking removeFromParent];
    isWalking =false;
    SKAction *animate =[SKAction animateWithTextures:_jumpingFrames
                                        timePerFrame:0.1f
                                              resize:YES restore:YES];
    SKAction *remove = [SKAction removeFromParent];
    
    
    [_jumping runAction:[SKAction sequence:@[animate,remove]]];
    isWalking = true;
    if(isWalking == true)
    {
        [self performSelector:@selector(redoWalking) withObject:self afterDelay:0.4];
        
    }
    return;
}

-(void)redoWalking
{
    [self setup];
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

@end
