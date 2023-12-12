using Godot;
using System;
using WzComparerR2.WzLib;

public static partial class WzLib
{
	public static Wz_Structure wzs = new();
	
	static WzLib(){
		wzs.WzVersionVerifyMode = WzVersionVerifyMode.Fast;
		string baseWz = @".\Data\Base.wz";  // <- change to your own    
		wzs.Load(baseWz, true);
	}
	
	static Wz_Node FindWz(string path)
	{
		var fullPath = path.Split('/', '\\');
		var WzType = Enum.TryParse<Wz_Type>(fullPath[0], true, out var wzType) ? wzType : Wz_Type.Unknown;
		List<Wz_Node> preSearch = new List<Wz_Node>();
		if (WzType != Wz_Type.Unknown) //用wztype作为输入参数
		{
			IEnumerable<Wz_Structure> preSearchWz = Enumerable.Repeat(wzs, 1);
			foreach (var wzs in preSearchWz)
			{
				Wz_File baseWz = null;
				bool find = false;
				foreach (Wz_File wz_f in wzs.wz_files)
				{
					if (wz_f.Type == WzType)
					{
						preSearch.Add(wz_f.Node);
						find = true;
						//e.WzFile = wz_f;
					}
					if (wz_f.Type == Wz_Type.Base)
					{
						baseWz = wz_f;
					}
				}

				// detect data.wz
				if (baseWz != null && !find)
				{
					string key = WzType.ToString();
					foreach (Wz_Node node in baseWz.Node.Nodes)
					{
						if (node.Text == key && node.Nodes.Count > 0)
						{
							preSearch.Add(node);
						}
					}
				}
			}
		}

		foreach (var wzFileNode in preSearch)
		{
			var searchNode = wzFileNode;
			for (int i = 1; i < fullPath.Length && searchNode != null; i++)
			{
				searchNode = searchNode.Nodes[fullPath[i]];
				var img = searchNode.GetValueEx<Wz_Image>(null);
				if (img != null)
				{
					searchNode = img.TryExtract() ? img.Node : null;
				}
			}

			if (searchNode != null)
			{
				var WzNode = searchNode;
				return WzNode;
			}
		}

		return null;
	}


}
