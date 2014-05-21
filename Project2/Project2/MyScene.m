//
//  MyScene.m
//  Project2
//
//  Created by Student on 5/6/14.
//  Copyright (c) 2014 WEAREORGANIZED. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"

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

static const float BG_POINTS=100;

int tileWidth, randNumberX, onScreenTiles = 0;
int numWalls = 0;

@implementation MyScene
{
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    SKNode *_bglayer;
    SKNode *_tileLayer;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        //i want to see all the nodes, not just rendered ones
        [self.scene.view setValue:@(YES) forKey:@"_showsCulledNodesInNodeCount"];
        
        //set background node
        _bglayer=[SKNode node];
        [self addChild:_bglayer];
        
        //stuff node
        _tileLayer = [SKNode node];
        [self addChild:_tileLayer];
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        
        myLabel.text = @"Insert Game Here";
        myLabel.fontSize = 60;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        
        [self addChild:myLabel];
        for(int i =0; i<2;i++)
        {
            SKSpriteNode *bg= [SKSpriteNode spriteNodeWithImageNamed:@"background"];
            bg.anchorPoint = CGPointZero;
            bg.position = CGPointMake(i *bg.size.width, 0);
            bg.name =@"bg";
            [_bglayer addChild:bg];
            
            //look at chapter 5 page 136-141 for help about layers and correct positions of stuff
        }
        
        SKSpriteNode *temp = [SKSpriteNode spriteNodeWithImageNamed:@"wall"];
        temp.name = @"temp";
        temp.xScale = 1;
        temp.yScale = 1;
        temp.position = CGPointMake(tileWidth, 480);
        [_tileLayer addChild:temp];
        [self initWalls];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    SKScene *_gameOverScene = [[GameOverScene alloc] initWithSize:self.size];
    [self.view presentScene:_gameOverScene];
}

-(void)update:(CFTimeInterval)currentTime {
    //NSLog(@"updating");
    /* Called before each frame is rendered */
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
     _lastUpdateTime = currentTime;
    
    //NSLog([NSString stringWithFormat:@"BGLAYER's position: %f", _bglayer.position.x]);
    //NSLog([NSString stringWithFormat:@"onScreenTiles: %d", onScreenTiles]);
    SKAction *removeFromParent = [SKAction removeFromParent];
    SKAction *moveToLeft = [SKAction moveByX:-4 y:0 duration:0.01];
    [_bglayer enumerateChildNodesWithName:@"wall" usingBlock:^(SKNode *node, BOOL *stop)
     {
         //NSLog([NSString stringWithFormat:@"node.position.x: %f", node.position.x]);
         //NSLog([NSString stringWithFormat:@"tileWidth - bglayer.position: %f", (tileWidth- _bglayer.position.x)]);
         //NSLog([NSString stringWithFormat:@"node: %@", node]);
         [node runAction: [SKAction repeatActionForever:moveToLeft]];
            if (node.position.x < tileWidth - _bglayer.position.x)
            {
                //NSLog([NSString stringWithFormat:@"Removing a tile"]);
                --onScreenTiles;
                [node runAction:removeFromParent];
            }
         if (onScreenTiles < 10 || onScreenTiles < 0)
         {
             NSLog([NSString stringWithFormat: @"calling spawnWalls because on screen tiles is %d", onScreenTiles]);
             [self spawnWalls];
         }
     }];
    
   /* if (onScreenTiles < 10 || onScreenTiles < 0)
    {
        NSLog([NSString stringWithFormat: @"calling spawnWalls because on screen tiles is %d", onScreenTiles]);
        [self spawnWalls];
    }*/
    [self moveBG];
}
//moves the background and recycles it so it loops forever
-(void)moveBG
{
         //SKSpriteNode *bg = (SKSpriteNode *)node;
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

- (void)spawnWalls
{                                           //(upper bound-lower bound)+lower bound
    randNumberX = (((float)arc4random()/0x100000000)*((20-5)+5));
    
    SKSpriteNode *wall;
    for (int i = 0; i < randNumberX; i++)
    {
        /*SKSpriteNode */wall = [SKSpriteNode spriteNodeWithImageNamed:@"wall"];
        wall.name = @"wall";
        wall.xScale = 2;
        wall.yScale = 1;
        wall.position = CGPointMake((i * wall.size.width) + (wall.size.width * 6), 380);
        [_tileLayer addChild:wall];
        ++onScreenTiles;
    }
    tileWidth = wall.size.width;
    NSLog([NSString stringWithFormat:@"spawned %d new walls, now there should be %d", randNumberX, onScreenTiles]);
    randNumberX = 0;
}

- (void)initWalls
{                                           //(upper bound-lower bound)+lower bound
    randNumberX = (((float)arc4random()/0x100000000)*((20-5)+5));
    
    SKSpriteNode *wall;
    for (int i = 0; i < randNumberX; i++)
    {
        /*SKSpriteNode */wall = [SKSpriteNode spriteNodeWithImageNamed:@"wall"];
        wall.name = @"wall";
        wall.xScale = 2;
        wall.yScale = 1;
            //spawn close to the right side of the screen
        wall.position = CGPointMake((i * wall.size.width) + self.scene.size.width - 100, 380);
        [_tileLayer addChild:wall];
        ++onScreenTiles;
    }
    tileWidth = wall.size.width;
    NSLog([NSString stringWithFormat:@"Initializing walls, %d of them! and rand was %d", onScreenTiles, randNumberX]);
    randNumberX = 0;
    
}

- (int) countWalls
{
    numWalls = 0;
    [_tileLayer enumerateChildNodesWithName:@"wall" usingBlock:^(SKNode *node, BOOL *stop)
     {
         numWalls++;
         if (node.position.x < tileWidth/2)
             NSLog(@"SHOULD BE REMOVING");
     }];
    return numWalls;
}

@end
