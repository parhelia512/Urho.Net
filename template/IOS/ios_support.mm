/*************************************************************************/
/*  ios_support.mm                                                       */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2020 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2020 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#if  defined(IOS) || defined(TVOS)

#include "ios_support.h"
#include <mono/jit/jit.h>
#include <mono/metadata/environment.h>
#include <mono/utils/mono-publib.h>
#include <mono/metadata/mono-config.h>
#include <mono/metadata/assembly.h>
#import <Foundation/Foundation.h>
#include <os/log.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include "ios_aot_modules.h"

static void
register_dllmap (void)
{
    mono_dllmap_insert (NULL, "System.Native", NULL, "__Internal", NULL);
    mono_dllmap_insert (NULL, "System.IO.Compression.Native", NULL, "__Internal", NULL);
    mono_dllmap_insert (NULL, "System.Security.Cryptography.Native.Apple", NULL, "__Internal", NULL);
}


extern "C" void urho_mono_setup_aot();

namespace ios {
namespace support {


void urho_mono_setup_aot() {

    ios_aot_register_modules();
    
    mono_jit_set_aot_mode(MONO_AOT_MODE_FULL);
} // urho_mono_setup_aot


void register_arkit_types() { /*stub*/ };
void unregister_arkit_types() { /*stub*/ };
void register_camera_types() { /*stub*/ };
void unregister_camera_types() { /*stub*/ };


void initialize() {
	mono_dllmap_insert(NULL, "System.Native", NULL, "__Internal", NULL);
	mono_dllmap_insert(NULL, "System.IO.Compression.Native", NULL, "__Internal", NULL);
	mono_dllmap_insert(NULL, "System.Security.Cryptography.Native.Apple", NULL, "__Internal", NULL);

	urho_mono_setup_aot();
    
	mono_set_signal_chaining(true);
	mono_set_crash_chaining(true);
}

void cleanup() {
}

} // namespace support
} // namespace ios


// The following are P/Invoke functions required by the monotouch profile of the BCL.
// These are P/Invoke functions and not internal calls, hence why they use
// 'mono_bool' and 'const char*' instead of 'MonoBoolean' and 'MonoString*'.

#define GD_PINVOKE_EXPORT extern "C" __attribute__((visibility("default")))

GD_PINVOKE_EXPORT const char *xamarin_get_locale_country_code() {
	NSLocale *locale = [NSLocale currentLocale];
	NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
	if (countryCode == NULL) {
		return strdup("US");
	}
	return strdup([countryCode UTF8String]);
}

GD_PINVOKE_EXPORT void xamarin_log(const uint16_t *p_unicode_message) {
	int length = 0;
	const uint16_t *ptr = p_unicode_message;
	while (*ptr++)
		length += sizeof(uint16_t);
	NSString *msg = [[NSString alloc] initWithBytes:p_unicode_message length:length encoding:NSUTF16LittleEndianStringEncoding];

	os_log_info(OS_LOG_DEFAULT, "%{public}@", msg);
}

GD_PINVOKE_EXPORT const char *xamarin_GetFolderPath(int p_folder) {
	NSSearchPathDirectory dd = (NSSearchPathDirectory)p_folder;
	NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:dd inDomains:NSUserDomainMask] lastObject];
	NSString *path = [url path];
	return strdup([path UTF8String]);
}

GD_PINVOKE_EXPORT char *xamarin_timezone_get_local_name() {
	NSTimeZone *tz = nil;
	tz = [NSTimeZone localTimeZone];
	NSString *name = [tz name];
	return (name != nil) ? strdup([name UTF8String]) : strdup("Local");
}

GD_PINVOKE_EXPORT char **xamarin_timezone_get_names(uint32_t *p_count) {
	NSArray *array = [NSTimeZone knownTimeZoneNames];
	*p_count = (uint32_t)array.count;
	char **result = (char **)malloc(sizeof(char *) * (*p_count));
	for (uint32_t i = 0; i < *p_count; i++) {
		NSString *s = [array objectAtIndex:i];
		result[i] = strdup(s.UTF8String);
	}
	return result;
}

GD_PINVOKE_EXPORT void *xamarin_timezone_get_data(const char *p_name, uint32_t *p_size) { // FIXME: uint32_t since Dec 2019, unsigned long before
	NSTimeZone *tz = nil;
	if (p_name) {
		NSString *n = [[NSString alloc] initWithUTF8String:p_name];
		tz = [[NSTimeZone alloc] initWithName:n];
	} else {
		tz = [NSTimeZone localTimeZone];
	}
	NSData *data = [tz data];
	*p_size = (uint32_t)[data length];
	void *result = malloc(*p_size);
	memcpy(result, data.bytes, *p_size);
	return result;
}

GD_PINVOKE_EXPORT void xamarin_start_wwan(const char *p_uri) {
	// FIXME: What's this for? No idea how to implement.
	os_log_error(OS_LOG_DEFAULT, "Not implemented: 'xamarin_start_wwan'");
}

#endif // IPHONE_ENABLED
