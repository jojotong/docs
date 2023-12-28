# filebeat tail_files不生效

现象：
1. 配置采集文件，设置`tail_files`
```yaml
- type: log
  paths:
  - fake.log
  tail_files: true
```  
2. 采集开始之后，发现没有日志采上来
3. 用vi向文件中添加几行
4. 发现新旧内容一并采集了
   
原因：

vim 编辑文件时，inode发生了变化，而filebeat的registry以文件inode为准，它会认为是创建了新文件。
```bash
$ > fake.log
$ stat fake.log
  File: ‘fake.log’
  Size: 0               Blocks: 0          IO Block: 4096   regular empty file
Device: fd00h/64768d    Inode: 284066      Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2023-12-28 14:19:39.544654092 +0800
Modify: 2023-12-28 14:19:39.544654092 +0800
Change: 2023-12-28 14:19:39.544654092 +0800
 Birth: -
$ vi fake.log
$ stat fake.log
  File: ‘fake.log’
  Size: 4               Blocks: 8          IO Block: 4096   regular file
Device: fd00h/64768d    Inode: 284068      Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2023-12-28 14:19:56.508961575 +0800
Modify: 2023-12-28 14:19:56.508961575 +0800
Change: 2023-12-28 14:19:56.510961611 +0800
 Birth: -
``` 
所以这跟我们修改文件的方式有关，可以修改vim 策略，或者用`echo "xxx" >> fake.log`

ref:
- <https://discuss.elastic.co/t/filebeat-5-6-3-tail-files-not-working/106642>
- <https://unix.stackexchange.com/questions/36467/why-does-inode-value-change-when-we-edit-in-vi-editor>
