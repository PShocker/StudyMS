using Godot;
using System;
using WzComparerR2.WzLib;

public partial class Wz : Node
{
	
	public int Test()
	{
		Wz_Structure wzs = new();
		wzs.WzVersionVerifyMode = WzVersionVerifyMode.Fast;
		string baseWzFolder = @"C:\Nexon\Library\maplestory\appdata\Data\Base";  // <- change to your own
		string frontendPublicDir = @".\public";            // <- change to your own
		string wzRegion = "CMST";                          // <- change to your own
		try {
			wzs.LoadWzFolder(baseWzFolder, ref wzs.WzNode, true);
			int mapID = 100000000;
			int wzVersion = wzs.wz_files[0].Header.WzVersion;
		   	return wzVersion;
		} finally {
			wzs.Clear();
		}
	}
}
