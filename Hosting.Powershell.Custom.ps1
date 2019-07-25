param([string]$InitDesc)
$global:UserNames = @{};
$global:Desc = "";

function getPlatform($desc)
{
    $platform = "SEH";
    if($desc -like "*SEH*" -or $desc -like "*exchange*")
    {
        $platform = "SEH";
    }
    elseif($desc -like "*DEX*")
    {
        $platform = "DEX";
    }
    else
    {
        $platform = "PLR";
    }

    return $platform;
}

function getEnvironment($desc)
{
    $env = "";
    if($desc -like "*QA*")
    {
		$env = "QA";
    } 
    elseif($desc -like "*DEV*")
    {
		$env = "DEV";
    }

    return $env;
}

function getPlatformName($desc)
{
    $platform = getPlatform $desc;
    $env = getEnvironment $desc;

	if($env)
    {
    	$platform = $env+" "+$platform;
    }
	return $platform;
}

function getPlatformUrl($desc)
{
    $powerShellUrl = "";
    if($desc)
	{
	    $platform = getPlatform $desc;
	    $env = getEnvironment $desc;

	    if($platform -contains "SEH")
	    {
	        $powerShellUrl = "https://exchange.{0}intermedia.net/powershell";
	    }
	    elseif($platform -contains "DEX")
	    {
	        $powerShellUrl = "https://dex.{0}intermedia.net/powershell";
	    }
	    else
	    {
	        $powerShellUrl = "https://cp.{0}serverdata.net/powershell";   
	    }

	    $powerShellUrl = [string]::Format($powerShellUrl,$env);
	}
	
	return $powerShellUrl;
}

function getPlatformColor($platform)
{
    $platformColor = "";
    if($platform)
	{
	    if($platform -contains "SEH")
	    {
	        $platformColor = "Cyan";
	    }
	    elseif($platform -contains "DEX")
	    {
	        $platformColor = "DarkYellow";
	    }
	    else
	    {
	        $platformColor = "Magenta";
	    }
    }
    return $platformColor;
}

function prompt 
{ 
    $platform = "NOT CONNECTED";
	$platformColor = "Red";
    if($global:desc) 
	{
        $platform = getPlatform $global:desc;
        $platformColor = getPlatformColor $platform;

        $platform = getPlatformName $global:desc;
	}

    write-host "[" -ForegroundColor "Yellow" -NoNewLine;
    write-host $platform -ForegroundColor $platformColor -NoNewLine;
    write-host "]" $(get-location) -ForegroundColor "Yellow" -NoNewLine;
    write-host ">" -ForegroundColor "Green" -NoNewLine;
    if($platform -eq "PLR") 
    { 
		$title = "Control Panel PowerShell";
	} 
	else
	{
		$title = "HostPilot PowerShell: $platform";
	}

    $host.UI.RawUI.WindowTitle = $title;
    $host.UI.RawUI.BackgroundColor = "black"
    $host.UI.RawUI.ForegroundColor = "gray"

    return " "
}

function WidenWindow([int]$preferredWidth, [int]$preferredHeight)
{
	[int]$maxAllowedWindowWidth = $host.ui.rawui.MaxPhysicalWindowSize.Width
	if ($preferredWidth -lt $maxAllowedWindowWidth)
	{
		# first, buffer size has to be set to windowsize or more
		# this operation does not usually fail
		$current=$host.ui.rawui.BufferSize
		$bufferWidth = $current.width
		if ($bufferWidth -lt $preferredWidth)
		{
			$current.width=$preferredWidth
			$host.ui.rawui.BufferSize=$current
		}
		# else not setting BufferSize as it is already larger

		# setting window size. As we are well within max limit, it won't throw exception.
		$current = $host.ui.rawui.WindowSize
		if ($current.width -lt $preferredWidth)
		{
		  $current.width=$preferredWidth
		  $current.height=$preferredHeight
		  $host.ui.rawui.WindowSize=$current
		}
	#else not setting WindowSize as it is already larger
	}
}

<#
  Section: PSCredmanUtils
  Author : Jim Harrison (jim@isatools.org)
  Date   : 2012/05/20
#>
[String] $PsCredmanUtils = @"
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Management.Automation;
using System.Security.Permissions;
using System.Security;

namespace PsUtils
{
    public class CredMan
    {
		[DllImport("credui", EntryPoint = "CredUIPromptForCredentialsW", CharSet = CharSet.Unicode)]
		private static extern CredUIReturnCodes CredUIPromptForCredentials(ref CREDUI_INFO pUiInfo, string pszTargetName, IntPtr Reserved, int dwAuthError, StringBuilder pszUserName, int ulUserNameMaxChars, StringBuilder pszPassword, int ulPasswordMaxChars, ref int pfSave, CREDUI_FLAGS dwFlags);

		[DllImport("credui", EntryPoint = "CredUIConfirmCredentialsW", CharSet = CharSet.Unicode)]
		private static extern CredUIReturnCodes CredUIConfirmCredentials(string targetName, bool confirm);
  
		[Flags]
		private enum CREDUI_FLAGS
		{
			ALWAYS_SHOW_UI = 0x80,
			COMPLETE_USERNAME = 0x800,
			DO_NOT_PERSIST = 2,
			EXCLUDE_CERTIFICATES = 8,
			EXPECT_CONFIRMATION = 0x20000,
			GENERIC_CREDENTIALS = 0x40000,
			INCORRECT_PASSWORD = 1,
			KEEP_USERNAME = 0x100000,
			PASSWORD_ONLY_OK = 0x200,
			PERSIST = 0x1000,
			REQUEST_ADMINISTRATOR = 4,
			REQUIRE_CERTIFICATE = 0x10,
			REQUIRE_SMARTCARD = 0x100,
			SERVER_CREDENTIAL = 0x4000,
			SHOW_SAVE_CHECK_BOX = 0x40,
			CREDUI_FLAGS_EXPECT_CONFIRMATION = 0x20000,
			USERNAME_TARGET_CREDENTIALS = 0x80000,
			VALIDATE_USERNAME = 0x400
		}

		[StructLayout(LayoutKind.Sequential)]
		private struct CREDUI_INFO
		{
			public int cbSize;
			public IntPtr hwndParent;
			[MarshalAs(UnmanagedType.LPWStr)]
			public string pszMessageText;
			[MarshalAs(UnmanagedType.LPWStr)]
			public string pszCaptionText;
			public IntPtr hbmBanner;
		}

		private enum CredUIReturnCodes
		{
			ERROR_CANCELLED = 0x4c7,
			ERROR_INSUFFICIENT_BUFFER = 0x7a,
			ERROR_INVALID_ACCOUNT_NAME = 0x523,
			ERROR_INVALID_FLAGS = 0x3ec,
			ERROR_INVALID_PARAMETER = 0x57,
			ERROR_NO_SUCH_LOGON_SESSION = 0x520,
			ERROR_NOT_FOUND = 0x490,
			NO_ERROR = 0
		}

		public static void ConfirmCredential(string targetName, bool confirm)
		{
			CredUIReturnCodes codes = CredUIConfirmCredentials(targetName, confirm);
			if (codes != CredUIReturnCodes.NO_ERROR)
			{
				throw new ApplicationException("CredUIConfirmCredentials returned an error: " + codes.ToString());
			}
		}
		
		public static PSCredential PromptForCredential(string caption, string message, string userName, string targetName, PSCredentialTypes allowedCredentialTypes, PSCredentialUIOptions options, ref bool save)
		{
			PSCredential credential = null;
			if (string.IsNullOrEmpty(caption))
			{
				caption = "Credential Request";
			}
			if (string.IsNullOrEmpty(message))
			{
				message = "Enter your credentials.";
			}
			CREDUI_INFO structure = new CREDUI_INFO();
			structure.pszCaptionText = caption;
			structure.pszMessageText = message;
			StringBuilder pszUserName = new StringBuilder(userName, 0x201);
			StringBuilder pszPassword = new StringBuilder(0x100);
			int pfSave = Convert.ToInt32(save);
			structure.cbSize = Marshal.SizeOf(structure);
			structure.hwndParent = IntPtr.Zero;
			CREDUI_FLAGS dwFlags = CREDUI_FLAGS.SHOW_SAVE_CHECK_BOX;
			if ((allowedCredentialTypes & PSCredentialTypes.Domain) != PSCredentialTypes.Domain)
			{
				dwFlags |= CREDUI_FLAGS.GENERIC_CREDENTIALS;
				if ((options & PSCredentialUIOptions.AlwaysPrompt) == PSCredentialUIOptions.AlwaysPrompt)
				{
					dwFlags |= CREDUI_FLAGS.ALWAYS_SHOW_UI;
				}
			}
			CredUIReturnCodes codes = CredUIReturnCodes.ERROR_INVALID_PARAMETER;
			if ((pszUserName.Length <= 0x201) && (pszPassword.Length <= 0x100))
			{
				codes = CredUIPromptForCredentials(ref structure, targetName, IntPtr.Zero, 0, pszUserName, 0x201, pszPassword, 0x100, ref pfSave, dwFlags);
				save = Convert.ToBoolean(pfSave);
			}
			if (codes == CredUIReturnCodes.NO_ERROR)
			{
				string str = null;
				if (pszUserName != null)
				{
					str = pszUserName.ToString();
				}
				SecureString password = new SecureString();
				for (int i = 0; i < pszPassword.Length; i++)
				{
					password.AppendChar(pszPassword[i]);
					pszPassword[i] = '\0';
				}
				if (!string.IsNullOrEmpty(str))
				{
					credential = new PSCredential(str, password);
				}
				else
				{
					credential = null;
				}
			}
			else
			{
				if (codes != CredUIReturnCodes.ERROR_CANCELLED)
				{
					throw new OperationCanceledException("CredUIPromptForCredentials returned an error: " + codes.ToString());
				}
				credential = null;
			}
			return credential;
		}
				
        #region Imports
        // DllImport derives from System.Runtime.InteropServices
        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode)]
        private static extern bool CredDeleteW([In] string target, [In] CRED_TYPE type, [In] int reservedFlag);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredEnumerateW", CharSet = CharSet.Unicode)]
        private static extern bool CredEnumerateW([In] string Filter, [In] int Flags, out int Count, out IntPtr CredentialPtr);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredFree")]
        private static extern void CredFree([In] IntPtr cred);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredReadW", CharSet = CharSet.Unicode)]
        private static extern bool CredReadW([In] string target, [In] CRED_TYPE type, [In] int reservedFlag, out IntPtr CredentialPtr);

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredWriteW", CharSet = CharSet.Unicode)]
        private static extern bool CredWriteW([In] ref Credential userCredential, [In] UInt32 flags);
        #endregion

        #region Fields
        public enum CRED_ERRORS : uint
        {
            ERROR_SUCCESS = 0x0,
            ERROR_INVALID_PARAMETER = 0x80070057,
            ERROR_INVALID_FLAGS = 0x800703EC,
            ERROR_NOT_FOUND = 0x80070490,
            ERROR_NO_SUCH_LOGON_SESSION = 0x80070520,
            ERROR_BAD_USERNAME = 0x8007089A
        }

        public enum CRED_PERSIST : uint
        {
            SESSION = 1,
            LOCAL_MACHINE = 2,
            ENTERPRISE = 3
        }

        public enum CRED_TYPE : uint
        {
            GENERIC = 1,
            DOMAIN_PASSWORD = 2,
            DOMAIN_CERTIFICATE = 3,
            DOMAIN_VISIBLE_PASSWORD = 4,
            GENERIC_CERTIFICATE = 5,
            DOMAIN_EXTENDED = 6,
            MAXIMUM = 7,      // Maximum supported cred type
            MAXIMUM_EX = (MAXIMUM + 1000),  // Allow new applications to run on old OSes
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct Credential
        {
            public UInt32 Flags;
            public CRED_TYPE Type;
            public string TargetName;
            public string Comment;
            public DateTime LastWritten;
            public UInt32 CredentialBlobSize;
            public string CredentialBlob;
            public CRED_PERSIST Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public string TargetAlias;
            public string UserName;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct NativeCredential
        {
            public UInt32 Flags;
            public CRED_TYPE Type;
            public IntPtr TargetName;
            public IntPtr Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public UInt32 CredentialBlobSize;
            public IntPtr CredentialBlob;
            public UInt32 Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public IntPtr TargetAlias;
            public IntPtr UserName;
        }
        #endregion

        #region Child Class
        private class CriticalCredentialHandle : Microsoft.Win32.SafeHandles.CriticalHandleZeroOrMinusOneIsInvalid
        {
            public CriticalCredentialHandle(IntPtr preexistingHandle)
            {
                SetHandle(preexistingHandle);
            }

            private Credential XlateNativeCred(IntPtr pCred)
            {
                NativeCredential ncred = (NativeCredential)Marshal.PtrToStructure(pCred, typeof(NativeCredential));
                Credential cred = new Credential();
                cred.Type = ncred.Type;
                cred.Flags = ncred.Flags;
                cred.Persist = (CRED_PERSIST)ncred.Persist;

                long LastWritten = ncred.LastWritten.dwHighDateTime;
                LastWritten = (LastWritten << 32) + ncred.LastWritten.dwLowDateTime;
                cred.LastWritten = DateTime.FromFileTime(LastWritten);

                cred.UserName = Marshal.PtrToStringUni(ncred.UserName);
                cred.TargetName = Marshal.PtrToStringUni(ncred.TargetName);
                cred.TargetAlias = Marshal.PtrToStringUni(ncred.TargetAlias);
                cred.Comment = Marshal.PtrToStringUni(ncred.Comment);
                cred.CredentialBlobSize = ncred.CredentialBlobSize;
                if (0 < ncred.CredentialBlobSize)
                {
                    cred.CredentialBlob = Marshal.PtrToStringUni(ncred.CredentialBlob, (int)ncred.CredentialBlobSize / 2);
                }
                return cred;
            }

            public Credential GetCredential()
            {
                if (IsInvalid)
                {
                    throw new InvalidOperationException("Invalid CriticalHandle!");
                }
                Credential cred = XlateNativeCred(handle);
                return cred;
            }

            public Credential[] GetCredentials(int count)
            {
                if (IsInvalid)
                {
                    throw new InvalidOperationException("Invalid CriticalHandle!");
                }
                Credential[] Credentials = new Credential[count];
                IntPtr pTemp = IntPtr.Zero;
                for (int inx = 0; inx < count; inx++)
                {
                    pTemp = Marshal.ReadIntPtr(handle, inx * IntPtr.Size);
                    Credential cred = XlateNativeCred(pTemp);
                    Credentials[inx] = cred;
                }
                return Credentials;
            }

            override protected bool ReleaseHandle()
            {
                if (IsInvalid)
                {
                    return false;
                }
                CredFree(handle);
                SetHandleAsInvalid();
                return true;
            }
        }
        #endregion

        #region Custom API
        public static int CredDelete(string target, CRED_TYPE type)
        {
            if (!CredDeleteW(target, type, 0))
            {
                return Marshal.GetHRForLastWin32Error();
            }
            return 0;
        }

        public static int CredEnum(string Filter, out Credential[] Credentials)
        {
            int count = 0;
            int Flags = 0x0;
            if (string.IsNullOrEmpty(Filter) ||
                "*" == Filter)
            {
                Filter = null;
                if (6 <= Environment.OSVersion.Version.Major)
                {
                    Flags = 0x1; //CRED_ENUMERATE_ALL_CREDENTIALS; only valid is OS >= Vista
                }
            }
            IntPtr pCredentials = IntPtr.Zero;
            if (!CredEnumerateW(Filter, Flags, out count, out pCredentials))
            {
                Credentials = null;
                return Marshal.GetHRForLastWin32Error(); 
            }
            CriticalCredentialHandle CredHandle = new CriticalCredentialHandle(pCredentials);
            Credentials = CredHandle.GetCredentials(count);
            return 0;
        }

        public static int CredRead(string target, CRED_TYPE type, out Credential Credential)
        {
            IntPtr pCredential = IntPtr.Zero;
            Credential = new Credential();
            if (!CredReadW(target, type, 0, out pCredential))
            {
                return Marshal.GetHRForLastWin32Error();
            }
            CriticalCredentialHandle CredHandle = new CriticalCredentialHandle(pCredential);
            Credential = CredHandle.GetCredential();
            return 0;
        }

        public static int CredWrite(Credential userCredential)
        {
            if (!CredWriteW(ref userCredential, 0))
            {
                return Marshal.GetHRForLastWin32Error();
            }
            return 0;
        }

        #endregion

        private static int AddCred()
        {
            Credential Cred = new Credential();
            string Password = "Password";
            Cred.Flags = 0;
            Cred.Type = CRED_TYPE.GENERIC;
            Cred.TargetName = "Target";
            Cred.UserName = "UserName";
            Cred.AttributeCount = 0;
            Cred.Persist = CRED_PERSIST.ENTERPRISE;
            Cred.CredentialBlobSize = (uint)Password.Length;
            Cred.CredentialBlob = Password;
            Cred.Comment = "Comment";
            return CredWrite(Cred);
        }

        private static bool CheckError(string TestName, CRED_ERRORS Rtn)
        {
            switch(Rtn)
            {
                case CRED_ERRORS.ERROR_SUCCESS:
                    Console.WriteLine(string.Format("'{0}' worked", TestName));
                    return true;
                case CRED_ERRORS.ERROR_INVALID_FLAGS:
                case CRED_ERRORS.ERROR_INVALID_PARAMETER:
                case CRED_ERRORS.ERROR_NO_SUCH_LOGON_SESSION:
                case CRED_ERRORS.ERROR_NOT_FOUND:
                case CRED_ERRORS.ERROR_BAD_USERNAME:
                    Console.WriteLine(string.Format("'{0}' failed; {1}.", TestName, Rtn));
                    break;
                default:
                    Console.WriteLine(string.Format("'{0}' failed; 0x{1}.", TestName, Rtn.ToString("X")));
                    break;
            }
            return false;
        }

        /*
         * Note: the Main() function is primarily for debugging and testing in a Visual 
         * Studio session.  Although it will work from PowerShell, it's not very useful.
         */
        public static void Main()
        {
            Credential[] Creds = null;
            Credential Cred = new Credential();
            int Rtn = 0;

            Console.WriteLine("Testing CredWrite()");
            Rtn = AddCred();
            if (!CheckError("CredWrite", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredEnum()");
            Rtn = CredEnum(null, out Creds);
            if (!CheckError("CredEnum", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredRead()");
            Rtn = CredRead("Target", CRED_TYPE.GENERIC, out Cred);
            if (!CheckError("CredRead", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredDelete()");
            Rtn = CredDelete("Target", CRED_TYPE.GENERIC);
            if (!CheckError("CredDelete", (CRED_ERRORS)Rtn))
            {
                return;
            }
            Console.WriteLine("Testing CredRead() again");
            Rtn = CredRead("Target", CRED_TYPE.GENERIC, out Cred);
            if (!CheckError("CredRead", (CRED_ERRORS)Rtn))
            {
                Console.WriteLine("if the error is 'ERROR_NOT_FOUND', this result is OK.");
            }
        }
    }
}
"@

$PsCredMan = $null
try
{
	$PsCredMan = [PsUtils.CredMan];
}
catch
{
	$Error.RemoveAt($Error.Count - 1);
}
if ($null -eq $PsCredMan) { Add-Type $PsCredmanUtils; }

[HashTable] $ErrorCategory = @{0x80070057 = "InvalidArgument";
                               0x800703EC = "InvalidData";
                               0x80070490 = "ObjectNotFound";
                               0x80070520 = "SecurityError";
                               0x8007089A = "SecurityError"}

function Remove-Creds
{
	Param([Parameter(Mandatory=$true)][String] $Target);
    [Int] $Results = 0;
	try
	{
		$Results = [PsUtils.CredMan]::CredDelete($Target, [PsUtils.CredMan+CRED_TYPE]::GENERIC);
	}
	catch
	{
		return $_;
	}
	switch ($Results)
	{
        0 { break }
        0x80070490 { break } #ERROR_NOT_FOUND
        default
        {
    		[String] $Msg = "Failed to delete from target '$Target' credentials store for '$Env:UserName'"
    		[Management.ManagementException] $MgmtException = New-Object Management.ManagementException($Msg)
    		[Management.Automation.ErrorRecord] $ErrRcd = New-Object Management.Automation.ErrorRecord($MgmtException, $Results.ToString("X"), $ErrorCategory[$Results], $null)
    		return $ErrRcd
        }
	}
	return $Cred
}
							   
function Read-Creds
{
	Param([Parameter(Mandatory=$true)][AllowEmptyString()][String] $Target)
	[PsUtils.CredMan+Credential] $Cred = New-Object PsUtils.CredMan+Credential
    [Int] $Results = 0
	try
	{
		$Results = [PsUtils.CredMan]::CredRead($Target, [PsUtils.CredMan+CRED_TYPE]::GENERIC, [ref]$Cred)
	}
	catch
	{
		return $_
	}
	switch($Results)
	{
        0 { break }
        0x80070490 { break } #ERROR_NOT_FOUND
        default
        {
    		[String] $Msg = "Failed to read from target '$Target' credentials store for '$Env:UserName'"
    		[Management.ManagementException] $MgmtException = New-Object Management.ManagementException($Msg)
    		[Management.Automation.ErrorRecord] $ErrRcd = New-Object Management.Automation.ErrorRecord($MgmtException, $Results.ToString("X"), $ErrorCategory[$Results], $null)
    		return $ErrRcd
        }
	}
	return $Cred
}

function Write-Creds
{
	Param(
		[Parameter(Mandatory=$true)][AllowEmptyString()][String] $Target,
		[Parameter(Mandatory=$true)][String] $UserName,
		[Parameter(Mandatory=$true)][String] $Password,
		[Parameter(Mandatory=$false)][String] $Comment = [String]::Empty,
		[Parameter(Mandatory=$false)][Boolean] $EntStrg = $false
	)
	if ([String]::IsNullOrEmpty($Target))
	{
		$Target = $UserName
	}
    if ([String]::IsNullOrEmpty($Comment) -or 256 -lt $Comment.Length)
	{
        $Comment = [String]::Format("Last edited by {0}\{1} on {2}",
                                    $Env:UserDomain,
                                    $Env:UserName,
                                    $Env:ComputerName)
    }
	[Int] $Persist = [PsUtils.CredMan+CRED_PERSIST]::LOCAL_MACHINE
	[String] $DomainName = [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName
	if(-not [String]::IsNullOrEmpty($DomainName) -or ($EntStrg -and -not [String]::IsNullOrEmpty($DomainName))){
		$Persist = [PsUtils.CredMan+CRED_PERSIST]::ENTERPRISE
	}
	[PsUtils.CredMan+Credential] $Cred = New-Object PsUtils.CredMan+Credential
	$Cred.Flags = 0
	$Cred.Type = [PsUtils.CredMan+CRED_TYPE]::GENERIC
	$Cred.TargetName = $Target
	$Cred.UserName = $UserName
	$Cred.AttributeCount = 0
	$Cred.Persist = $Persist
	$Cred.CredentialBlobSize = [Text.Encoding]::Unicode.GetBytes($Password).Length
	$Cred.CredentialBlob = $Password
	$Cred.Comment = $Comment
	[Int] $Results = 0
	try
	{
		$Results = [PsUtils.CredMan]::CredWrite($Cred)
	}
	catch
	{
		return $_
	}
	if (0 -ne $Results)
	{
		[String] $Msg = "Failed to write to credentials store for target '$Target' using '$UserName', '$Password', '$Comment'"
		[Management.ManagementException] $MgmtException = New-Object Management.ManagementException($Msg)
		[Management.Automation.ErrorRecord] $ErrRcd = New-Object Management.Automation.ErrorRecord($MgmtException, $Results.ToString("X"), $ErrorCategory[$Results], $null)
		return $ErrRcd
	}
	return $Results
}

function GetHPCred([string]$plat, [string]$credentialType, [bool]$IgnoreExisting)
{	
	$URL = getPlatformUrl $plat
	$target = ([String]::Format("{0}.{1}",$credentialType,$URL));	
	if ((CheckHPCred -plat $plat -credentialType $credentialType ) -and !$IgnoreExisting)
	{
		$credObj = Read-Creds -Target $target
		$password = $credObj.CredentialBlob | ConvertTo-SecureString -asPlainText -Force;
		$cred = New-Object System.Management.Automation.PsCredential($credObj.UserName,$password);
		Remove-Variable -Name credObj,pwd -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue; #contains plaintext PW
	}
	else
	{
		$success = $false
		while (!$success)
		{
			try 
			{
				$save = $false;
				$cred = [PsUtils.CredMan]::PromptForCredential("Please enter credentials", "Please enter your credentials.", [Environment]::UserName, $target, "Generic", "None", [ref] $save);
				if ($cred)
				{
					$success = Test-HPCredential -cred $cred -plat $plat;
					if(-not $success)
					{							
						Remove-Creds -Target $target;
						$cred = $null;
					}				
				}
				else
				{
					Write-Host "Operation cancelled.";
					exit;
				}
			}
			catch 
			{
				exit; 
			}
		}
		if ($save)
		{
			Write-Host "Saving credentials ...";
			Set-SavedHPCredential -cred $cred -plat $plat -credentialType $credentialType;
			Write-Host "To clear saved credentials use Clear-SavedHPCredential command.";
		}
	}
	return $cred
}

function CheckHPCred([string]$plat, [string]$credentialType)
{
	$URL = getPlatformUrl $plat
    $target = [String]::Format("{0}.{1}", $credentialType, $URL);
	$credObj = Read-Creds -Target $target
	if (([string]$credObj.Username).length -gt 0)
	{
		return $true
	}
	else
	{
		return $false
	}
}

function Set-SavedHPCredential([string]$plat, [string]$credentialType, [Management.Automation.PSCredential]$cred)
{
	if(-not $cred)
	{
		throw "Credential required.";
	}
	$URL = getPlatformUrl $plat;
    $target = [String]::Format("{0}.{1}",$credentialType,$URL);
	Write-Host -ForegroundColor DarkGray "Saving credentials ..." -NoNewline;
	$pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password));
	Write-Creds -Target $target -UserName $cred.UserName -Password $pw | Out-Null;
	Remove-Variable -Name pw -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue; #contains plaintext pw
	Write-Host -ForegroundColor DarkGray " success.";
}

function Clear-SavedHPCredential
{
	$platform = getPlatform $global:desc;
	$URL = getPlatformUrl $platform;
    $target = [String]::Format("{0}.{1}",$global:CredentialType,$URL); 

	Write-Host -ForegroundColor DarkGray "Removing saved credentials ..." -NoNewline;
	Remove-Creds -Target $target;
	Remove-Variable -Name pw -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue; #contains plaintext pw
	Write-Host -ForegroundColor DarkGray " success.";
}

function Test-HPCredential([string]$plat, [Management.Automation.PSCredential]$cred)
{
	$URL = getPlatformUrl $plat;
	Write-Host -ForegroundColor DarkGray "Testing credentials ..." -NoNewline;
	try
	{
		New-PSSession -name:$plat -ConnectionUri $URL -Credential $cred -Authentication Basic -ConfigurationName IntermediaCredTest -ErrorAction Stop | Remove-PSSession;
		throw "Condition not allowed. Please check the code."
	}
	catch
	{
		if ($_.ErrorDetails.Message -like "*IntermediaCredTest*")
		{
			Write-Host -ForegroundColor DarkGray " success."
			return $true
		}
		else
		{
			Write-Host -ForegroundColor Red " failed."
			return $false
		}
	}
}

function ConnectHP([string]$plat, [Management.Automation.PSCredential]$cred)
{
	$URL = getPlatformUrl $plat;
	Write-Host -ForegroundColor DarkGray "Trying $(getPlatformURL($plat)) ..." -NoNewline;
	$session = New-PSSession -Name:$plat -ConfigurationName Hosting.PowerShell -Authentication Basic -ConnectionUri $URL -Credential $cred;
	if ($session)
	{
		Write-Host -ForegroundColor DarkGray " success.";
		return $session;
	}
	else
	{
		Write-Host -ForegroundColor Red " failed.";
		return $false;
	}
}

function connect($desc, $showCommands, $credType)
{    
    if (-not $desc)
    {
        $desc = $InitDesc;
    }
	
    if (-not $desc)
    {
        $desc = Read-Host "Enter a platform name (seh, dex, plr, ...)";
    } 
	
	$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))
	$platform = getPlatform $desc;
	
	if (-not $credType)
	{ 
		$credType =$InitCredType;
	}
	
    $credType="User"

#    if (-not $credType)
#    {
#       $admin = New-Object System.Management.Automation.Host.ChoiceDescription "&Administrator", `
#		"Administrator mode.";
#        $user = New-Object System.Management.Automation.Host.ChoiceDescription "&User", `
#		"User mode.";
#        $options = [System.Management.Automation.Host.ChoiceDescription[]]($admin, $user);
#		if($platform -eq "PLR") 
#	    { 
#			write-host "-----------------------------------------------------------------`n"
#			write-host "`t Welcome to Control Panel PowerShell`n"
#			write-host "-----------------------------------------------------------------"
#			write-host "For help use faq article:  https:/faq.intermedia.net/Article/23641 `n"
#			$result = $host.ui.PromptForChoice("", "Please use ‘Administrator’ credential type to login to your Partner Account", $options, 0);  			
#		}
#		else
#		{
#			write-host "-----------------------------------------------------------------`n"
#			write-host "`t Welcome to Intermedia HostPilot PowerShell`n"
#			write-host "-----------------------------------------------------------------"
#			write-host "For help use kb article:  https://kb.intermedia.net/Article/23283 `n"
#			$result = $host.ui.PromptForChoice("", "Please use ‘User’ credential type to login your account", $options, 1);
#		}
#        
#        switch ($result)
#        {
#            0 {$credType="Administrator"}
#            1 {$credType="User"}
#        }                      
#    }	
	
    $powerShellUrl = getPlatformUrl $desc;
    $platformName = getPlatformName $desc;
	
    try
    {
	    $existingSession = Get-PSSession | where {$_.Name -eq $platformName };
		if( $global:CredentialType -ne $credType -and $existingSession)
		{
			close $platformName;
			$existingSession = $null;
		}
		
	    $foundSession = $existingSession;

	    if (-not $existingSession)
	    {
			$creds = GetHPCred -plat $platformName -credentialType $credType -IgnoreExisting $true
			# Because all output is captured, and returned. The return keyword in function just indicates a logical exit point.
			if($creds.GetType().FullName -eq 'System.Object[]' )
			{
				$creds = $creds[-1]
			}
			$existingSession = ConnectHP -plat $platformName -cred $creds
	    }

        if ($existingSession)
		{
		    $importedSession = Import-PSSession $existingSession -AllowClobber;        
		    if (-not $foundSession)
	    	{
				if ($showCommands) 
				{
					$importedSession.ExportedCommands.Values | Select-Object Name;
				}
				
				if($credType -eq "User")
				{
					Set-ConnectionSettings -Credential $creds -CredentialType $credType -AccountID TDC2013;
				}
				else
				{
					Set-ConnectionSettings -Credential $creds -CredentialType $credType;
				}
			
            	$global:UserNames[$platformName] = $creds.UserName;
	    	}

		    Write-Host "Connection to $platformName was successful." -ForegroundColor Yellow
			$global:CredentialType = $credType;			
		    $global:desc = $platformName;
		}
    } 
	catch 
	{
		#Process-Exception $_.Exception 100
	    $global:desc = "";
	    Write-Warning "Cannot connect to $platformName : $($_.Exception.Message)";
	}
}

function close($desc)
{
    if ($desc)
    {
        $platformName = getPlatformName $desc;
        Get-PSSession | where { $_.Name -eq $platformName } | Remove-PSSession;
		if ($global:desc -eq $platformName)
		{
		    $global:desc = "";
		}
    }
    else
    {
        Get-PSSession | Remove-PSSession;
		$global:desc = "";
    }
}

function Process-Exception { param ([Exception]$exception, [int]$eventID)

    $dateTime = Get-Date
	write-host ("EventID:`t" + $eventID)
    write-host ("Exception Source:`t" + $exception.Source)
    write-host ("Error Code:`t"+ $exception.NativeErrorCode)
    write-host ("Exception Message:" + $exception.Message)
    write-host ("Stack Trace:`t" + $exception.StackTrace + "`r`n`r`n")
}

WidenWindow 120 50

set-alias list       format-list 
set-alias table      format-table
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force;

connect $InitDesc $false $InitCredType;
# SIG # Begin signature block
# MIIW2QYJKoZIhvcNAQcCoIIWyjCCFsYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9PMMPEClFj33b/2gZ78bkZ5W
# snagghIzMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSZMIIDgaADAgECAhBxoLc2ld2xr8I7K5oY7lTLMA0GCSqGSIb3
# DQEBCwUAMIGpMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMdGhhd3RlLCBJbmMuMSgw
# JgYDVQQLEx9DZXJ0aWZpY2F0aW9uIFNlcnZpY2VzIERpdmlzaW9uMTgwNgYDVQQL
# Ey8oYykgMjAwNiB0aGF3dGUsIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25s
# eTEfMB0GA1UEAxMWdGhhd3RlIFByaW1hcnkgUm9vdCBDQTAeFw0xMzEyMTAwMDAw
# MDBaFw0yMzEyMDkyMzU5NTlaMEwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwx0aGF3
# dGUsIEluYy4xJjAkBgNVBAMTHXRoYXd0ZSBTSEEyNTYgQ29kZSBTaWduaW5nIENB
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAm1UCTBcF6dBmw/wordPA
# /u/g6X7UHvaqG5FG/fUW7ZgHU/q6hxt9nh8BJ6u50mfKtxAlU/TjvpuQuO0jXELv
# ZCVY5YgiGr71x671voqxERGTGiKpdGnBdLZoh6eDMPlk8bHjOD701sH8Ev5zVxc1
# V4rdUI0D+GbNynaDE8jXDnEd5GPJuhf40bnkiNIsKMghIA1BtwviL8KA5oh7U2zD
# RGOBf2hHjCsqz1v0jElhummF/WsAeAUmaRMwgDhO8VpVycVQ1qo4iUdDXP5Nc6VJ
# xZNp/neWmq/zjA5XujPZDsZC0wN3xLs5rZH58/eWXDpkpu0nV8HoQPNT8r4pNP5f
# +QIDAQABo4IBFzCCARMwLwYIKwYBBQUHAQEEIzAhMB8GCCsGAQUFBzABhhNodHRw
# Oi8vdDIuc3ltY2IuY29tMBIGA1UdEwEB/wQIMAYBAf8CAQAwMgYDVR0fBCswKTAn
# oCWgI4YhaHR0cDovL3QxLnN5bWNiLmNvbS9UaGF3dGVQQ0EuY3JsMB0GA1UdJQQW
# MBQGCCsGAQUFBwMCBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCAQYwKQYDVR0RBCIw
# IKQeMBwxGjAYBgNVBAMTEVN5bWFudGVjUEtJLTEtNTY4MB0GA1UdDgQWBBRXhptU
# uL6mKYrk9sLiExiJhc3ctzAfBgNVHSMEGDAWgBR7W0XPr87Lev0xkhpqtvNG61dI
# UDANBgkqhkiG9w0BAQsFAAOCAQEAJDv116A2E8dD/vAJh2jRmDFuEuQ/Hh+We2tM
# Hoeei8Vso7EMe1CS1YGcsY8sKbfu+ZEFuY5B8Sz20FktmOC56oABR0CVuD2dA715
# uzW2rZxMJ/ZnRRDJxbyHTlV70oe73dww78bUbMyZNW0c4GDTzWiPKVlLiZYIRsmO
# /HVPxdwJzE4ni0TNB7ysBOC1M6WHn/TdcwyR6hKBb+N18B61k2xEF9U+l8m9ByxW
# dx+F3Ubov94sgZSj9+W3p8E3n3XKVXdNXjYpyoXYRUFyV3XAeVv6NBAGbWQgQrc6
# yB8dRmQCX8ZHvvDEOihU2vYeT5qiGUOkb0n4/F5CICiEi0cgbjCCBKMwggOLoAMC
# AQICEA7P9DjI/r81bgTYapgbGlAwDQYJKoZIhvcNAQEFBQAwXjELMAkGA1UEBhMC
# VVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1h
# bnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzIwHhcNMTIxMDE4MDAw
# MDAwWhcNMjAxMjI5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3lt
# YW50ZWMgQ29ycG9yYXRpb24xNDAyBgNVBAMTK1N5bWFudGVjIFRpbWUgU3RhbXBp
# bmcgU2VydmljZXMgU2lnbmVyIC0gRzQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQCiYws5RLi7I6dESbsO/6HwYQpTk7CY260sD0rFbv+GPFNVDxXOBD8r
# /amWltm+YXkLW8lMhnbl4ENLIpXuwitDwZ/YaLSOQE/uhTi5EcUj8mRY8BUyb05X
# oa6IpALXKh7NS+HdY9UXiTJbsF6ZWqidKFAOF+6W22E7RVEdzxJWC5JH/Kuu9mY9
# R6xwcueS51/NELnEg2SUGb0lgOHo0iKl0LoCeqF3k1tlw+4XdLxBhircCEyMkoyR
# LZ53RB9o1qh0d9sOWzKLVoszvdljyEmdOsXF6jML0vGjG/SLvtmzV4s73gSneiKy
# JK4ux3DFvk6DJgj7C72pT5kI4RAocqrNAgMBAAGjggFXMIIBUzAMBgNVHRMBAf8E
# AjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBzBggr
# BgEFBQcBAQRnMGUwKgYIKwYBBQUHMAGGHmh0dHA6Ly90cy1vY3NwLndzLnN5bWFu
# dGVjLmNvbTA3BggrBgEFBQcwAoYraHR0cDovL3RzLWFpYS53cy5zeW1hbnRlYy5j
# b20vdHNzLWNhLWcyLmNlcjA8BgNVHR8ENTAzMDGgL6AthitodHRwOi8vdHMtY3Js
# LndzLnN5bWFudGVjLmNvbS90c3MtY2EtZzIuY3JsMCgGA1UdEQQhMB+kHTAbMRkw
# FwYDVQQDExBUaW1lU3RhbXAtMjA0OC0yMB0GA1UdDgQWBBRGxmmjDkoUHtVM2lJj
# Fz9eNrwN5jAfBgNVHSMEGDAWgBRfmvVuXMzMdJrU3X3vP9vsTIAu3TANBgkqhkiG
# 9w0BAQUFAAOCAQEAeDu0kSoATPCPYjA3eKOEJwdvGLLeJdyg1JQDqoZOJZ+aQAMc
# 3c7jecshaAbatjK0bb/0LCZjM+RJZG0N5sNnDvcFpDVsfIkWxumy37Lp3SDGcQ/N
# lXTctlzevTcfQ3jmeLXNKAQgo6rxS8SIKZEOgNER/N1cdm5PXg5FRkFuDbDqOJqx
# OtoJcRD8HHm0gHusafT9nLYMFivxf1sJPZtb4hbKE4FtAC44DagpjyzhsvRaqQGv
# FZwsL0kb2yK7w/54lFHDhrGCiF3wPbRRoXkzKy57udwgCRNx62oZW8/opTBXLIlJ
# P7nPf8m/PiJoY1OavWl0rMUdPH+S4MO8HNgEdTCCBPkwggPhoAMCAQICEDblSA2A
# uFMTqomMXGbrFScwDQYJKoZIhvcNAQELBQAwTDELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDHRoYXd0ZSwgSW5jLjEmMCQGA1UEAxMddGhhd3RlIFNIQTI1NiBDb2RlIFNp
# Z25pbmcgQ0EwHhcNMTUxMjI5MDAwMDAwWhcNMTkwMTI3MjM1OTU5WjCBkjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcUDU1vdW50YWlu
# IFZpZXcxHDAaBgNVBAoUE0ludGVybWVkaWEubmV0LCBJbmMxGjAYBgNVBAsUEUlu
# dGVybmV0IFNlcnZpY2VzMRwwGgYDVQQDFBNJbnRlcm1lZGlhLm5ldCwgSW5jMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwJllkxS4w59ePfcd7QbOwDaU
# E/0JGu9BHNLnB47eO6RfkDBjIPRgl5vf2Ga3THAr/T0G9qZpJfOctPx6EhVlQQ0D
# OiRHq1Er1ZAPpf6/W+ApCYpOuapab0on6huyvxZaCPg3j/0nx3dC6lltjZDk89J5
# KTF+IJ/g3voI62o1EI0X9XTDgl0E5A+0hMm3HQIEQHCxNNbEHaqvV+S8sPOZ0f5L
# E2xwP2WNHWrnHWmXFZ2SEmEGREso2XYKei7ast6JzMJDBU9rwdEJTYHC1Y7JyAWj
# Hma5k19T5hqA/0y6nqrlxQGGweqk1FCjyDPtb3U2k0rgwkDR3U+kS4tDak4UwwID
# AQABo4IBjjCCAYowCQYDVR0TBAIwADAfBgNVHSMEGDAWgBRXhptUuL6mKYrk9sLi
# ExiJhc3ctzAdBgNVHQ4EFgQUja2ta0M+R4f9iJINukGZyqIeM7IwKwYDVR0fBCQw
# IjAgoB6gHIYaaHR0cDovL3RsLnN5bWNiLmNvbS90bC5jcmwwDgYDVR0PAQH/BAQD
# AgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHMGA1UdIARsMGowaAYLYIZIAYb4RQEH
# MAIwWTAmBggrBgEFBQcCARYaaHR0cHM6Ly93d3cudGhhd3RlLmNvbS9jcHMwLwYI
# KwYBBQUHAgIwIwwhaHR0cHM6Ly93d3cudGhhd3RlLmNvbS9yZXBvc2l0b3J5MB0G
# A1UdBAQWMBQwDjAMBgorBgEEAYI3AgEWAwIHgDBXBggrBgEFBQcBAQRLMEkwHwYI
# KwYBBQUHMAGGE2h0dHA6Ly90bC5zeW1jZC5jb20wJgYIKwYBBQUHMAKGGmh0dHA6
# Ly90bC5zeW1jYi5jb20vdGwuY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQBCV2CHADkN
# b7Nxr74vsa7V/l3RPijsqjlI7gvoI+tb1a/jMNUyO1B0b/L+zrgs/7gpWV9GD9R5
# +0JXVjEPBTv87T8j5FWqRMPD0CFudTNdXOwUyLZ/fjLBEpsa5yZ8qUkz27yBYUsk
# EuE9JvEWGINqUIhAbZwIIZEjP0SpyUOsv92jJPf1+alnohzG4OaylZflzKdjFbm3
# KMhxHO0UvFi6FnOnQC28i8sDK9Q249t0ADTzC/q74QlNuJ62LieVU0MWbkIO8XxB
# t2C0mq2YfkY1vQ+Kpqh6HvqFCanIQkB0HLXIvXSK2wYdhzWAK+T1SYfX3epDhkZt
# CSLm0Qi5xe0DMYIEEDCCBAwCAQEwYDBMMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# dGhhd3RlLCBJbmMuMSYwJAYDVQQDEx10aGF3dGUgU0hBMjU2IENvZGUgU2lnbmlu
# ZyBDQQIQNuVIDYC4UxOqiYxcZusVJzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIB
# DDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEE
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFjAjBgkqhkiG9w0BCQQxFgQUO14AudFZ4i8B
# vIS6NR42B74a1L0wDQYJKoZIhvcNAQEBBQAEggEATP4JD7zF0rym8J4gdF+1Lbib
# JuMzPNdterGdOwqKI4sQD8RDXseHY4KJMn+Lcsbvor6zwTYLCGhqZrk/RetDGINQ
# Zl59MHTHlxVSX2xMbIF2ZnSF1RAREMnpmw90Qb6pMMu+09YphoFrsZWuVta8wTix
# nI14nF+b1ZekFW/JDqz7w9EBJX9TFjXa445yZxCibMciJQnOhPkEm2/XTEqQZxZN
# neVkZFa2HpOUfUQAzQdd6suaLAjKvNzQZ529LhaO+RHNwz7jIb5nZbPiQUpQK6YL
# zRCxXOnKApkdXPJf5G+mFMrmknC8UNfe7W72l2WDnbm6/j6nCNjR9CzOvCMcyqGC
# AgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0w
# GwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMg
# VGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQ
# MAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3
# DQEJBTEPFw0xNjA5MDExNDAyNDlaMCMGCSqGSIb3DQEJBDEWBBQR8b+LdAUMGa8w
# R5ZKkXJM7L9QEjANBgkqhkiG9w0BAQEFAASCAQAfqLgpwwG2kSdbpFmLZg8+lgk+
# pGXKfmqiah0TetvmHEZuVgeyd6yg6tmkr4Jv5D353/aWCYiy/RzqOLBKCf0zUczc
# UY0HlHSEyXztX4ioL1H3nbdurWTnxTBfDK/uJ8rLk1ePWQzy+Y5zLHOguDxlDOMS
# IL1E2EUzHbVPIKo6c3QUr7fTS5fliXj6hion5nwrsZvz7Zvt8FrOdf63LtHocA7H
# bg3gKarB6zkDU+1SdoR33MPIy7jNqOyxBdbb3zMibeJ2hA3g+f1CMFi3RCWeTuh3
# I5zhRdQAXjfJKe/fnuFdr0qB8zUb944LBQdhT7oGPVtG8aZQzhD1Qo7sjF2l
# SIG # End signature block
