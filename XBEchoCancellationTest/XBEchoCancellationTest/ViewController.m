//
//  ViewController.m
//  XBEchoCancellationTest
//
//  Created by xxb on 2018/3/28.
//  Copyright © 2018年 xxb. All rights reserved.
//

#import "ViewController.h"
#import "XBEchoCancellation.h"
#import "XBAudioPlayer.h"

#define subPathPCM @"/Documents/xbMedia"
#define stroePath [NSHomeDirectory() stringByAppendingString:subPathPCM]

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *openBtn;
@property (nonatomic,strong) XBAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIButton *record;
@property (weak, nonatomic) IBOutlet UIButton *play;
@property (nonatomic,strong) NSData *dataStore;
@end

@implementation ViewController

UInt32 _readerLength;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self.audioPlayer playWithErrorBlock:nil];
}

- (IBAction)openOrCloseEchoCancellation:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected)
    {
        [[XBEchoCancellation shared] openEchoCancellation];
    }
    else
    {
        
        [[XBEchoCancellation shared] closeEchoCancellation];
    }
}


- (IBAction)record:(UIButton *)sender {
    [self.audioPlayer continuePlay];
    sender.selected = !sender.selected;
    [[XBEchoCancellation shared] closeEchoCancellation];
    if ([XBEchoCancellation shared].bl_input == nil)
    {
        [XBEchoCancellation shared].bl_input = ^(AudioBufferList *bufferList) {
            AudioBuffer buffer = bufferList->mBuffers[0];
            NSData *pcmBlock = [NSData dataWithBytes:buffer.mData length:buffer.mDataByteSize];
            
//            NSLog(@"------->>数据%@",pcmBlock);
            
            NSString *savePath = stroePath;
            if ([[NSFileManager defaultManager] fileExistsAtPath:savePath] == false)
            {
                [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
            }
            NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
            [handle seekToEndOfFile];
            [handle writeData:pcmBlock];
        };
    }

    if (sender.selected)
    {
        [self delete];
        [[XBEchoCancellation shared] startInput];
        self.openBtn.hidden = NO;
    }
    else
    {
        [[XBEchoCancellation shared] stopInput];
        self.openBtn.hidden = YES;
    }
}
- (IBAction)play:(UIButton *)sender {
    [self.audioPlayer pause];
    
    typeof(self) __weak weakSelf = self;
    self.dataStore = [NSData dataWithContentsOfFile:stroePath];
    [[XBEchoCancellation shared] stopInput];
    self.record.selected = NO;
    _readerLength = 0;
    if ([XBEchoCancellation shared].bl_output == nil)
    {
        [XBEchoCancellation shared].bl_output = ^(AudioBufferList *bufferList, UInt32 inNumberFrames) {
            AudioBuffer buffer = bufferList->mBuffers[0];
            
            int len = readData(buffer.mData, buffer.mDataByteSize,weakSelf.dataStore);
            buffer.mDataByteSize = len;
            
            if (len == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf play:weakSelf.play];
                });
            }
        };
    }

    sender.selected = !sender.selected;
    
    if (sender.selected)
    {
        [[XBEchoCancellation shared] startOutput];
    }
    else
    {
        [[XBEchoCancellation shared] stopOutput];
    }

}

int readData(Byte *data, int len, NSData *dataStore)
{
    UInt32 currentReadLength = 0;
    
    if (_readerLength >= dataStore.length)
    {
        _readerLength = 0;
        return currentReadLength;
    }
    if (_readerLength+ len <= dataStore.length)
    {
        _readerLength = _readerLength + len;
        currentReadLength = len;
    }
    else
    {
        currentReadLength = (UInt32)(dataStore.length - _readerLength);
        _readerLength = (UInt32) dataStore.length;
    }
    
    NSData *subData = [dataStore subdataWithRange:NSMakeRange(_readerLength, currentReadLength)];
    Byte *tempByte = (Byte *)[subData bytes];
    memcpy(data,tempByte,currentReadLength);
    
    
    return currentReadLength;
}


- (void)delete{
    NSString *pcmPath = stroePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pcmPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:pcmPath error:nil];
    }
}


///pcm转WAV
- (void)pcm2WAV
{
    NSString *pcmPath = stroePath;
    
    NSString *wavPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/xbMedia.wav"];
    char *pcmPath_c = (char *)[pcmPath UTF8String];
    char *wavPath_c = (char *)[wavPath UTF8String];
    convertPcm2Wav(pcmPath_c, wavPath_c, 1, kRate);
    //进入沙盒找到xbMedia.wav即可
}



// pcm 转wav

//wav头的结构如下所示：

typedef  struct  {
    
    char        fccID[4];
    
    int32_t      dwSize;
    
    char        fccType[4];
    
} HEADER;

typedef  struct  {
    
    char        fccID[4];
    
    int32_t      dwSize;
    
    int16_t      wFormatTag;
    
    int16_t      wChannels;
    
    int32_t      dwSamplesPerSec;
    
    int32_t      dwAvgBytesPerSec;
    
    int16_t      wBlockAlign;
    
    int16_t      uiBitsPerSample;
    
}FMT;

typedef  struct  {
    
    char        fccID[4];
    
    int32_t      dwSize;
    
}DATA;

/*
 int convertPcm2Wav(char *src_file, char *dst_file, int channels, int sample_rate)
 请问这个方法怎么用?参数都是什么意思啊
 
 赞  回复
 code书童： @不吃鸡爪 pcm文件路径，wav文件路径，channels为通道数，手机设备一般是单身道，传1即可，sample_rate为pcm文件的采样率，有44100，16000，8000，具体传什么看你录音时候设置的采样率。
 */

int convertPcm2Wav(char *src_file, char *dst_file, int channels, int sample_rate)

{
    int bits = 16;
    
    //以下是为了建立.wav头而准备的变量
    
    HEADER  pcmHEADER;
    
    FMT  pcmFMT;
    
    DATA  pcmDATA;
    
    unsigned  short  m_pcmData;
    
    FILE  *fp,*fpCpy;
    
    if((fp=fopen(src_file,  "rb"))  ==  NULL) //读取文件
        
    {
        
        printf("open pcm file %s error\n", src_file);
        
        return -1;
        
    }
    
    if((fpCpy=fopen(dst_file,  "wb+"))  ==  NULL) //为转换建立一个新文件
        
    {
        
        printf("create wav file error\n");
        
        return -1;
        
    }
    
    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
    
    strncpy(pcmHEADER.fccID,"RIFF",4);
    
    strncpy(pcmHEADER.fccType,"WAVE",4);
    
    fseek(fpCpy,sizeof(HEADER),1); //跳过HEADER的长度，以便下面继续写入wav文件的数据;
    
    //以上是创建wav头的HEADER;
    
    if(ferror(fpCpy))
        
    {
        
        printf("error\n");
        
    }
    
    //以下是创建wav头的FMT;
    
    pcmFMT.dwSamplesPerSec=sample_rate;
    
    pcmFMT.dwAvgBytesPerSec=pcmFMT.dwSamplesPerSec*sizeof(m_pcmData);
    
    pcmFMT.uiBitsPerSample=bits;
    
    strncpy(pcmFMT.fccID,"fmt  ", 4);
    
    pcmFMT.dwSize=16;
    
    pcmFMT.wBlockAlign=2;
    
    pcmFMT.wChannels=channels;
    
    pcmFMT.wFormatTag=1;
    
    //以上是创建wav头的FMT;
    
    fwrite(&pcmFMT,sizeof(FMT),1,fpCpy); //将FMT写入.wav文件;
    
    //以下是创建wav头的DATA;  但由于DATA.dwsize未知所以不能写入.wav文件
    
    strncpy(pcmDATA.fccID,"data", 4);
    
    pcmDATA.dwSize=0; //给pcmDATA.dwsize  0以便于下面给它赋值
    
    fseek(fpCpy,sizeof(DATA),1); //跳过DATA的长度，以便以后再写入wav头的DATA;
    
    fread(&m_pcmData,sizeof(int16_t),1,fp); //从.pcm中读入数据
    
    while(!feof(fp)) //在.pcm文件结束前将他的数据转化并赋给.wav;
        
    {
        
        pcmDATA.dwSize+=2; //计算数据的长度；每读入一个数据，长度就加一；
        
        fwrite(&m_pcmData,sizeof(int16_t),1,fpCpy); //将数据写入.wav文件;
        
        fread(&m_pcmData,sizeof(int16_t),1,fp); //从.pcm中读入数据
        
    }
    
    fclose(fp); //关闭文件
    
    pcmHEADER.dwSize = 0;  //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
    
    rewind(fpCpy); //将fpCpy变为.wav的头，以便于写入HEADER和DATA;
    
    fwrite(&pcmHEADER,sizeof(HEADER),1,fpCpy); //写入HEADER
    
    fseek(fpCpy,sizeof(FMT),1); //跳过FMT,因为FMT已经写入
    
    fwrite(&pcmDATA,sizeof(DATA),1,fpCpy);  //写入DATA;
    
    fclose(fpCpy);  //关闭文件
    
    return 0;
    
}


-(XBAudioPlayer *)audioPlayer
{
    if (_audioPlayer == nil)
    {
        _audioPlayer = [XBAudioPlayer new];
        
        //NSString *path0 = [[NSBundle mainBundle] pathForResource:@"周杰伦-晴天.mp3" ofType:nil];
        //NSString *path5 = @"http://qqma.tingge123.com:823/mp3/2016-06-01/1464765547.mp3";//晴天在线、
        //_audioPlayer.arr_urlStrs = @[path0];
        NSString *path0 = [[NSBundle mainBundle] pathForResource:@"周杰伦-晴天.mp3" ofType:nil];
        _audioPlayer.arr_urlStrs = @[path0,path0];
        
        _audioPlayer.b_autoPlayNext = YES;
        _audioPlayer.bl_playProgress = ^(XBAVPlayer *player, CGFloat progress, CGFloat current, CGFloat total) {
            NSLog(@"当前进度：%f, 播放了：%f, 总共：%f",progress,current,total);
        };
        
        _audioPlayer.bl_bufferBlock = ^(XBAVPlayer *player, CGFloat totalBuffer) {
            NSLog(@"已经缓冲了：%f",totalBuffer);
        };
    }
    return _audioPlayer;
}
@end
