﻿// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//   
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

namespace Carbon.Security
{
	public enum HttpUrlAccessRights
	{
		// https://msdn.microsoft.com/en-us/library/aa364653.aspx
		Read = -2147483648, // Because 0x80000000 isn't allowed!?
		Listen = 0x20000000,   // GENERIC_EXECUTE
		Delegate = 0x40000000,   // GENERIC_WRITE
		ListenAndDelegate = 0x10000000
	}
}
