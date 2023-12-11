using Godot;
using System;
using WzComparerR2.WzLib;
using Newtonsoft.Json;
using System.Drawing.Imaging;
using System.Drawing;

public partial class Wz : Node
{
	
	public static List<Byte[]> ResourceList=new List<byte[]>();
	public String Test()
	{
		Wz_Structure wzs = new();
		wzs.WzVersionVerifyMode = WzVersionVerifyMode.Fast;
		string baseWz = @".\Data\Base.wz";  // <- change to your own                         // <- change to your own
		try {
			//wzs.LoadWzFolder(baseWzFolder, ref wzs.WzNode, true);
			wzs.Load(baseWz, true);
			int mapID = 10000;
			int wzVersion = wzs.wz_files[0].Header.WzVersion;
			Wz_Node mapImgNode;
			if(mapID<100000000){
				mapImgNode = wzs.WzNode.FindNodeByPath(true, "Map", "Map", $"Map{mapID / 100000000}", $"0000{mapID}.img");
			}else{
				mapImgNode = wzs.WzNode.FindNodeByPath(true, "Map", "Map", $"Map{mapID / 100000000}", $"{mapID}.img");
			}
			// Load map manifest
			MapInfo mapInfo = new();
			for (int layer = 0; layer < 8; layer++)
			{
				Wz_Node layerNode = mapImgNode.FindNodeByPath(layer.ToString());

				// load tile
				Wz_Node tileRootNode = layerNode.FindNodeByPath("tile");
				if (tileRootNode != null && tileRootNode.Nodes.Count > 0) {
					var tileClass = layerNode.FindNodeByPath(@"info\tS").GetValue<string>();
					mapInfo.Layers[layer].Tiles = tileRootNode.Nodes.Select(tileNode=>{
						string resourceUrl = string.Format("Map/Tile/{0}.img/{1}/{2}",
							tileClass,
							tileNode.FindNodeByPath("u").GetValue<string>(),
							tileNode.FindNodeByPath("no").GetValueEx<int>(0)
						);
						return new MapTile() {
							ID = int.Parse(tileNode.Text),
							X = tileNode.FindNodeByPath("x").GetValueEx<int>(0),
							Y = tileNode.FindNodeByPath("y").GetValueEx<int>(0),
							Resource = LoadSpriteBase<Sprite>(wzs, resourceUrl),
						};
					}).ToList();
				}
				
				// load obj
				Wz_Node objRootNode = layerNode.FindNodeByPath("obj");
				if (objRootNode != null && objRootNode.Nodes.Count > 0)
				{
					mapInfo.Layers[layer].Objs = objRootNode.Nodes.Select(objNode =>
					{
						string resourceUrl = string.Format("Map/Obj/{0}.img/{1}/{2}/{3}",
							objNode.FindNodeByPath("oS").GetValue<string>(),
							objNode.FindNodeByPath("l0").GetValue<string>(),
							objNode.FindNodeByPath("l1").GetValue<string>(),
							objNode.FindNodeByPath("l2").GetValue<string>()
						);
						return new MapObj() {
							ID = int.Parse(objNode.Text),
							X = objNode.FindNodeByPath("x").GetValueEx<int>(0),
							Y = objNode.FindNodeByPath("y").GetValueEx<int>(0),
							Z = objNode.FindNodeByPath("z").GetValueEx<int>(0),
							FlipX = objNode.FindNodeByPath("f").GetValueEx<int>(0) != 0,
							Resource = LoadAnimation(wzs, resourceUrl),
						};
					}).ToList();
				}
				
				// load map back
				Wz_Node backRootNode = mapImgNode.FindNodeByPath("back");
				if (backRootNode != null) {
					mapInfo.Backs = backRootNode.Nodes.Select(backNode=>{
						int ani = backNode.FindNodeByPath("ani").GetValueEx<int>(0);
						string resourceUrl = string.Format("Map/Back/{0}.img/{1}/{2}",
							backNode.FindNodeByPath("bS").GetValue<string>(),
							ani switch {
								0 => "back",
								1 => "ani",
								2 => "spine",
								_ => throw new Exception($"unknown back ani={ani} at {backNode.FullPathToFile}"),
							},
							backNode.FindNodeByPath("no").GetValue<string>()
						);

						object backResource = ani switch
						{
							0 => LoadSpriteBase<Sprite>(wzs, resourceUrl),
							1 => LoadAnimation(wzs, resourceUrl),
							2 => throw new NotImplementedException("spine is not supported"),
							_ => throw new Exception($"unknown back ani={ani} at {backNode.FullPathToFile}"),
						};
						
						return new MapBack(){
							ID = int.Parse(backNode.Text),
							X = backNode.FindNodeByPath("x").GetValueEx<int>(0),
							Y = backNode.FindNodeByPath("y").GetValueEx<int>(0),
							Cx = backNode.FindNodeByPath("cx").GetValueEx<int>(0),
							Cy = backNode.FindNodeByPath("cy").GetValueEx<int>(0),
							Rx = backNode.FindNodeByPath("rx").GetValueEx<int>(0),
							Ry = backNode.FindNodeByPath("ry").GetValueEx<int>(0),
							Alpha = backNode.FindNodeByPath("a").GetValueEx<int>(0),
							FlipX = backNode.FindNodeByPath("f").GetValueEx<int>(0) != 0,
							Front = backNode.FindNodeByPath("front").GetValueEx<int>(0) != 0,
							Ani = ani,
							Type = backNode.FindNodeByPath("type").GetValueEx<int>(0),
							Resource = backResource,
						};
					}).ToArray();
				}
			}
			
			Wz_Node fhListNode = mapImgNode.FindNodeByPath("foothold");
			if (fhListNode != null)
			{
				int _layer, _z, _fh;
				List<MapFootHold> mapFootHoldList=new List<MapFootHold>();
				foreach (Wz_Node layerNode in fhListNode.Nodes)
				{
					Int32.TryParse(layerNode.Text, out _layer);
					MapFootHold mapFootHold=new();
					mapFootHold.Layer=_layer;   
					mapFootHold.FootHolds=new();
					mapFootHoldList.Add(mapFootHold);
					foreach (Wz_Node zNode in layerNode.Nodes)
					{
						Int32.TryParse(zNode.Text, out _z);
						foreach (Wz_Node fhNode in zNode.Nodes)
						{
							Int32.TryParse(fhNode.Text, out _fh);

							Wz_Node x1 = fhNode.FindNodeByPath("x1"),
								x2 = fhNode.FindNodeByPath("x2"),
								y1 = fhNode.FindNodeByPath("y1"),
								y2 = fhNode.FindNodeByPath("y2"),
								prev = fhNode.FindNodeByPath("prev"),
								next = fhNode.FindNodeByPath("next"),
								piece = fhNode.FindNodeByPath("piece");

							FootHold footHold = new FootHold();

							footHold.X1 = x1.GetValueEx<int>(0);
							footHold.X2 = x2.GetValueEx<int>(0);
							footHold.Y1 = y1.GetValueEx<int>(0);
							footHold.Y2 = y2.GetValueEx<int>(0);
							footHold.Prev = prev.GetValueEx<int>(0);
							footHold.Next = next.GetValueEx<int>(0);
							footHold.Piece = piece.GetValueEx<int>(0);

							mapFootHold.FootHolds.Add(footHold);

						}
					}
				}
				mapInfo.FootHolds=mapFootHoldList.ToArray();
			}
		   	return JsonConvert.SerializeObject(mapInfo);
		} finally {
			wzs.Clear();
		}
	}
	
	static T LoadSpriteBase<T>(Wz_Node pngNode) where T : Sprite, new() {
		// resolve uol
		pngNode = pngNode.ResolveUol();
		// resolve link
		var linkedPngNode = GetLinkedSourceNode(pngNode) ?? pngNode;
		var png = linkedPngNode.GetValue<Wz_Png>() ?? throw new Exception($"{pngNode.FullPathToFile} is not a PNG node");
		var origin = pngNode.FindNodeByPath("origin").GetValueEx<Wz_Vector>(null);
		var sprite = new T(){
			Width = png.Width,
			Height = png.Height,
			OriginX = origin?.X ?? 0,
			OriginY = origin?.Y ?? 0,
			Z = pngNode.FindNodeByPath("z").GetValueEx<int>(0),
			ResourceUrl = SavePngFile(linkedPngNode),
		};
		if (sprite is Frame frame) {
			frame.Delay = pngNode.FindNodeByPath("delay").GetValueEx<int>(100);
			frame.A0 = pngNode.FindNodeByPath("a0").GetValueEx<int>(255);
			frame.A1 = pngNode.FindNodeByPath("a1").GetValueEx<int>(255);
		}
		return sprite;
	}
	
	static Wz_Node GetLinkedSourceNode(Wz_Node node)
	{
		Wz_Node findNode(string fullPath) => node.GetNodeWzFile().WzStructure?.WzNode.FindNodeByPath(true, fullPath.Split('/'));
		
		string path;

		if (!string.IsNullOrEmpty(path = node.Nodes["source"].GetValueEx<string>(null)))
		{
			return findNode(path);
		}
		else if (!string.IsNullOrEmpty(path = node.Nodes["_inlink"].GetValueEx<string>(null)))
		{
			var img = node.GetNodeWzImage();
			return img?.Node.FindNodeByPath(true, path.Split('/'));
		}
		else if (!string.IsNullOrEmpty(path = node.Nodes["_outlink"].GetValueEx<string>(null)))
		{
			return findNode(path);
		}
		else
		{
			return node;
		}
	}
	
	static T LoadSpriteBase<T>(Wz_Structure wzs, string resourceUrl) where T : Sprite, new()
	{
		var pngNode = wzs.WzNode.FindNodeByPath(true, resourceUrl.Split('/')) ?? throw new Exception("Failed to find sprite "+resourceUrl);
		return LoadSpriteBase<T>(pngNode);
	}
	
	static FrameAnimate LoadAnimation(Wz_Structure wzs, string resourceUrl) {
		var aniNode = wzs.WzNode.FindNodeByPath(true, resourceUrl.Split('/')) ?? throw new Exception("Failed to find ani "+resourceUrl);
		var frames = new List<Frame>();
		for (int f = 0; ; f++)
		{
			var pngNode = aniNode.FindNodeByPath(f.ToString());
			if (pngNode == null) break;
			var frame = LoadSpriteBase<Frame>(pngNode);
			frames.Add(frame);
		}
		if (frames.Count == 0) throw new Exception("load 0 frames at " + resourceUrl);
		return new FrameAnimate(){
			Frames = frames
		};
	}
	
	static int SavePngFile(Wz_Node pngNode) {
		var bytes = pngNode.GetValue<Wz_Png>().ExtractPngBytes();
		ResourceList.Add(bytes);
		return ResourceList.Count-1;
	}
	
	static Byte[] GetResource(int i)
	{
		return ResourceList[i];
	}
	
	 class MapInfo
	{
		public int ID { get; set; }
		public MapLayer[] Layers { get; } = Enumerable.Range(0, 8).Select(_ => new MapLayer()).ToArray();
		public MapBack[] Backs { get; set; }
		public MapFootHold[] FootHolds { get; set; }
	}

	class MapFootHold
	{
		public int Layer { get; set; }
		public List<FootHold> FootHolds { get; set; }
	}
	
	class FootHold
	{
		public int ID {get;set;}
		public int X1 { get; set; }
		public int Y1 { get; set; }
		public int X2 { get; set; }
		public int Y2 { get; set; }
		public int Prev { get; set; }
		public int Next { get; set; }
		public int Piece { get; set; }
	}
	
	class MapLayer
	{
		public List<MapTile> Tiles { get; set; }
		public List<MapObj> Objs { get; set; }
	}

	class MapTile
	{
		public int ID {get;set;}
		public int X { get; set; }
		public int Y { get; set; }
		public Sprite Resource {get;set;}
	}

	class MapObj
	{
		public int ID {get;set;}
		public int X { get; set; }
		public int Y { get; set; }
		public int Z { get; set; }
		public bool FlipX { get; set; }
		public FrameAnimate Resource { get; set; }
	}

	class MapBack
	{
		public int ID { get; set; }
		public int X { get; set; }
		public int Y { get; set; }
		public int Cx { get; set; }
		public int Cy { get; set; }
		public int Rx { get; set; }
		public int Ry { get; set; }
		public int Alpha { get; set; }
		public bool FlipX { get; set; }
		public bool Front { get; set; }
		public int Ani { get; set; }
		public int Type { get; set; }
		public object Resource { get; set; }
	}

	//--------------------------------------

	class Sprite
	{
		public int Width { get; set; }
		public int Height { get; set; }
		public int OriginX {get;set;}
		public int OriginY { get; set; }
		public int Z { get; set; }
		public int ResourceUrl { get; set; }
	}

	class Frame : Sprite
	{
		public int Delay {get;set;}
		public int A0 { get; set; }
		public int A1 { get; set; }
	}

	class FrameAnimate
	{
		public List<Frame> Frames { get; set; }
	}
}

