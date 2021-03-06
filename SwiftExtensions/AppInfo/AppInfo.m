//
//  AppMemoryInfoC.m
//  SwiftExtensions
//
//  Created by Kagen Zhao on 2016/11/22.
//  Copyright © 2016年 kagenZhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <ifaddrs.h>
#import <arpa/inet.h>

BOOL memoryInfo(vm_statistics_data_t *vmStats) {
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)vmStats, &infoCount);
    return kernReturn == KERN_SUCCESS;
}
void logMemoryInfo() {
    vm_statistics_data_t vmStats;
    if (memoryInfo(&vmStats)) {
        NSProcessInfo *info = [[NSProcessInfo alloc] init];
        printf("***======Memory Log Begin======***\n");
        printf("     Total:         %llu \n", info.physicalMemory);
        printf("     Free:          %lu  \n", (unsigned long)vmStats.free_count * vm_page_size);
        printf("     Active:        %lu  \n", (unsigned long)vmStats.active_count * vm_page_size);
        printf("     Inactive:      %lu  \n", (unsigned long)vmStats.inactive_count * vm_page_size);
        printf("     Wire:          %lu  \n", (unsigned long)vmStats.wire_count * vm_page_size);
        printf("     Zerofill:      %lu  \n", (unsigned long)vmStats.zero_fill_count * vm_page_size);
        printf("     Reactivations: %lu  \n", (unsigned long)vmStats.reactivations * vm_page_size);
        printf("     Pageins:       %lu  \n", (unsigned long)vmStats.pageins * vm_page_size);
        printf("     Pageouts:      %lu  \n", (unsigned long)vmStats.pageouts * vm_page_size);
        printf("     Faults:        %u   \n", vmStats.faults);
        printf("     Cow_faults:    %u   \n", vmStats.cow_faults);
        printf("     Lookups:       %u   \n", vmStats.lookups);
        printf("     Hits:          %u   \n", vmStats.hits);
        printf("***=======Memory Log End=======***\n");
    }
}

unsigned long long totalMemory() {
    NSProcessInfo *info = [[NSProcessInfo alloc] init];
    return info.physicalMemory;
}

unsigned long long freeMemory() {
    vm_statistics_data_t vmStats;
    if (memoryInfo(&vmStats)) {
        return vmStats.free_count * vm_page_size;
    }
    return NSNotFound;
}

// 获取当前任务所占用的内存
unsigned long long memoryUsage(){
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    task_info(mach_task_self(),
              MACH_TASK_BASIC_INFO,
              (task_info_t)&info,
              &size);
    return info.resident_size;
}

unsigned long long appUsageDiskSize(NSString *folder) {
    __block NSError *error;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:&error];
    __block unsigned long long size = 0;
    [contents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@", folder, obj] error:&error];
        size += [fileAttributes[NSFileSize] unsignedLongLongValue];
    }];
    return size;
}

// $0 / 1000 / 1000 / 1000
unsigned long long totalDiskSize() {
    struct statfs buf;
    unsigned long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0)
    {
        freeSpace = (unsigned long long)(buf.f_bsize * buf.f_blocks);
    }
    return freeSpace;
}

// $0 / 1000 / 1000 / 1000
unsigned long long diskAvailable() {
    struct statfs buf;
    unsigned long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0)
    {
        freeSpace = (unsigned long long)(buf.f_bsize * buf.f_bavail);
        /*
         * 上边算出来的 会跟系统设置里的数据不同, 需要减去可用wired(wire就是已使用，且不可被分页的内存)
         */
        vm_statistics_data_t vmStats;
        mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
        kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
        if (kernReturn == KERN_SUCCESS) {
            freeSpace = freeSpace - vmStats.wire_count * vm_page_size;
        }
    }

    return freeSpace;
}


NSString *getIpAddress() {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}
