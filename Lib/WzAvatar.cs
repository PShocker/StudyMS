using Godot;
using System;
using WzComparerR2.WzLib;

public partial class WzAvatar : Node
{
	public static int body=12000;	
	public static int eyes=20000;	
	public static int hair=30020;	
	public static int coat=1040002;	
	public static int pants=1060002;	
	
	public String GetAvatorJson(String path){
		Wz_Node node=WzLib.FindWz(path);
		
		return null;
	}
}
