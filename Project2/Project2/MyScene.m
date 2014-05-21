//
//  MyScene.m
//  Project2
//
//  Created by Student on 5/6/14.
//  Copyright (c) 2014 WEAREORGANIZED. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"

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

static const float BG_POINTS=100;

int tileWidth, _tempNumTiles, onScreenTiles = 0;
int numWalls = 0;
int minNumTiles = 8;
int maxNumTiles = 20;

@implementation MyScene
{
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    SKNode *_bglayer;
    SKNode *_tileLayer;
    SKAction *_moveToLeft;
    SKSpriteNode *_currentEnemy;
    int _stage_width, _stage_height;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        //i want to see all the nodes, not just rendered ones
        [self.scene.view setValue:@(YES) forKey:@"_showsCulledNodesInNodeCount"];
        
        //set background node
        _bglayer=[SKNode node];
        [self addChild:_bglayer];
        
        //stuff node- where the meat and potatoes are.
        _tileLayer = [SKNode node];
        [self addChild:_tileLayer];
        
        _stage_height = self.scene.size.height;
        _stage_width = self.scene.size.width;
        
        //self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        _moveToLeft = [SKAction moveByX:-4 y:0 duration:0.1];

        for(int i =0; i<2;i++)
        {
            SKSpriteNode *bg= [SKSpriteNode spriteNodeWithImageNamed:@"fullBackground"];//was just "background"
            bg.anchorPoint = CGPointZero;
            bg.position = CGPointMake(i *bg.size.width, 0);
            bg.name =@"bg";
            [_bglayer addChild:bg];
            
            //look at chapter 5 page 136-141 for help about layers and correct positions of stuff
        }
        
        [self spawnWalls:TRUE];
    }
    return self;
}

//touch logic
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    SKScene *_gameOverScene = [[GameOverScene alloc] initWithSize:self.size];
    [self.view presentScene:_gameOverScene];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
     _lastUpdateTime = currentTime;
    
    #pragma mark- tile update logic
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

#pragma mark spawn logic
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
        xPosition = firstTime ? (i * wall.size.width) + _stage_width - 100 : ((i * wall.size.width) + _stage_width) + (wall.size.width * 2);
        wall.position = CGPointMake(xPosition, yPosition);
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
        location = CGPointMake((arc4random_uniform(_stage_width) + (_stage_width/2)), -500);
        [self makeEnemy:location];
    }
}

-(void)makeEnemy: (CGPoint) location
{
    #pragma fix me when you get an enemy image
    _currentEnemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemyPictureHere"];
    _currentEnemy.position = location;
    [_tileLayer addChild:_currentEnemy];
}

@end
