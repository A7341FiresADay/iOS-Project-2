//
//  GameOverScene.m
//  Project2
//
//  Created by Student on 5/6/14.
//  Copyright (c) 2014 WEAREORGANIZED. All rights reserved.
//

#import "GameOverScene.h"
#import "MenuView.h"
#import "MyScene.h"

@implementation GameOverScene
{
    SKLabelNode *_textLabel;
    SKLabelNode *_playLabel;
    SKLabelNode *_quitLabel;
}
- (id)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    if (self) {
        SKSpriteNode *bg =
         [SKSpriteNode spriteNodeWithImageNamed:@"lose"];
         bg.position =
         CGPointMake(self.size.width/2, self.size.height/2);
         /*bg.position =
         CGPointMake(self.size.width / 2, self.size.height / 2);
         bg.anchorPoint = CGPointMake(0.5, 0.5); // same as default
         //bg.zRotation = M_PI / 8;*/
         [self addChild:bg];
        [self setBackgroundColor:[UIColor grayColor]];
        
        _textLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        _playLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        _quitLabel = [SKLabelNode labelNodeWithFontNamed:@"Menlo-Regular"];
        
        _textLabel.fontSize = 48;
        _playLabel.fontSize = 44;
        _quitLabel.fontSize = 44;
        
        _textLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+ 220);
        _playLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+ 80);
        _quitLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) -230);
        //CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
        
        _textLabel.text = @"Game Over!";
        _playLabel.text = @"Play Again";
        _quitLabel.text = @"Quit";
        
        [self addChild:_textLabel];
        [self addChild:_playLabel];
        [self addChild:_quitLabel];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    
    if (touchLocation.y > CGRectGetMidY(self.frame)+ 60)
    {
        MyScene * myScene = [[MyScene alloc] initWithSize:self.size];
        
        [self.view presentScene:myScene];
        
    }
    else exit(0);
}

@end
