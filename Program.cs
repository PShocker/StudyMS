// See https://aka.ms/new-console-template for more information
using WzComparerR2.WzLib;
using Newtonsoft.Json;
using System.Drawing.Imaging;
using Newtonsoft.Json.Linq;
using Google.Protobuf;

class Program
{
    public static List<Byte[]> ResourceList = new List<byte[]>();

    public static void Main(string[] args)
    {
        Wz_Structure wzs = new();
        wzs.WzVersionVerifyMode = WzVersionVerifyMode.Fast;
        string baseWzFolder = @"C:\Users\Shocker\Desktop\StudyMS\Data\Base.wz";  // <- change to your own
        string frontendPublicDir = @".\public";            // <- change to your own
        string wzRegion = "GMS";                          // <- change to your own

        try
        {
            wzs.Load(baseWzFolder, true);
            // wzs.Lo(baseWzFolder, ref wzs.WzNode, true);
            int mapID = 10000;
            int wzVersion = wzs.wz_files[0].Header.WzVersion;
            string outputDir = @$"{frontendPublicDir}\{wzRegion}-{wzVersion}";
            Wz_Node mapImgNode = wzs.WzNode.FindNodeByPath(true, "Map", "Map", $"Map{mapID / 100000000}", $"{mapID:000000000}.img");

            // Load map manifest
            MapImg mapImg = new();
            List<FootHold> footholds = new List<FootHold>();
            for (int layer = 0; layer < 8; layer++)
            {
                MapLayer mapLayer = new();
                Wz_Node layerNode = mapImgNode.FindNodeByPath(layer.ToString());

                // load tile
                Wz_Node tileRootNode = layerNode.FindNodeByPath("tile");
                if (tileRootNode != null && tileRootNode.Nodes.Count > 0)
                {
                    var tileClass = layerNode.FindNodeByPath(@"info\tS").GetValue<string>();

                    foreach (var tileNode in tileRootNode.Nodes)
                    {
                        string resourceUrl = string.Format("Map/Tile/{0}.img/{1}/{2}",
                            tileClass,
                            tileNode.FindNodeByPath("u").GetValue<string>(),
                            tileNode.FindNodeByPath("no").GetValueEx<int>(0)
                        );
                        MapTile mapTile = new()
                        {
                            Id = int.Parse(tileNode.Text),
                            X = tileNode.FindNodeByPath("x").GetValueEx<int>(0),
                            Y = tileNode.FindNodeByPath("y").GetValueEx<int>(0),
                            Resource = LoadSprite(wzs, resourceUrl),
                        };
                        mapLayer.Tile.Add(mapTile);
                    }
                }

                // load obj
                Wz_Node objRootNode = layerNode.FindNodeByPath("obj");
                if (objRootNode != null && objRootNode.Nodes.Count > 0)
                {

                    foreach (var objNode in objRootNode.Nodes)
                    {
                        string resourceUrl = string.Format("Map/Obj/{0}.img/{1}/{2}/{3}",
                            objNode.FindNodeByPath("oS").GetValue<string>(),
                            objNode.FindNodeByPath("l0").GetValue<string>(),
                            objNode.FindNodeByPath("l1").GetValue<string>(),
                            objNode.FindNodeByPath("l2").GetValue<string>()
                        );
                        MapObj mapObj = new()
                        {
                            Id = int.Parse(objNode.Text),
                            X = objNode.FindNodeByPath("x").GetValueEx<int>(0),
                            Y = objNode.FindNodeByPath("y").GetValueEx<int>(0),
                            Z = objNode.FindNodeByPath("z").GetValueEx<int>(0),
                            Flipx = objNode.FindNodeByPath("f").GetValueEx<int>(0) != 0,
                            Resource = LoadAnimation(wzs, resourceUrl),
                        };
                        mapLayer.Obj.Add(mapObj);
                    }
                }
                mapImg.Layer.Add(mapLayer);
            }

            // load map back
            Wz_Node backRootNode = mapImgNode.FindNodeByPath("back");
            if (backRootNode != null)
            {
                foreach (var backNode in backRootNode.Nodes)
                {
                    int ani = backNode.FindNodeByPath("ani").GetValueEx<int>(0);
                    string resourceUrl = string.Format("Map/Back/{0}.img/{1}/{2}",
                        backNode.FindNodeByPath("bS").GetValue<string>(),
                        ani switch
                        {
                            0 => "back",
                            1 => "ani",
                            2 => "spine",
                            _ => throw new Exception($"unknown back ani={ani} at {backNode.FullPathToFile}"),
                        },
                        backNode.FindNodeByPath("no").GetValue<string>()
                    );
                    MapBack mapBack = new()
                    {
                        Id = int.Parse(backNode.Text),
                        X = backNode.FindNodeByPath("x").GetValueEx<int>(0),
                        Y = backNode.FindNodeByPath("y").GetValueEx<int>(0),
                        Cx = backNode.FindNodeByPath("cx").GetValueEx<int>(0),
                        Cy = backNode.FindNodeByPath("cy").GetValueEx<int>(0),
                        Rx = backNode.FindNodeByPath("rx").GetValueEx<int>(0),
                        Ry = backNode.FindNodeByPath("ry").GetValueEx<int>(0),
                        Alpha = backNode.FindNodeByPath("a").GetValueEx<int>(0),
                        Flipx = backNode.FindNodeByPath("f").GetValueEx<int>(0) != 0,
                        Front = backNode.FindNodeByPath("front").GetValueEx<int>(0) != 0,
                        Ani = ani,
                        Type = backNode.FindNodeByPath("type").GetValueEx<int>(0),
                    };

                    switch (ani)
                    {
                        case 0:
                            mapBack.Sprite = LoadSprite(wzs, resourceUrl);
                            break;
                        case 1:
                            mapBack.Frameanimate = LoadAnimation(wzs, resourceUrl);
                            break;
                        case 2:
                            throw new NotImplementedException("spine is not supported");
                            break;
                    }
                    mapImg.Back.Add(mapBack);
                }
            }



            Wz_Node fhListNode = mapImgNode.FindNodeByPath("foothold");
            MapFootHold mapFootHold = new();
            if (fhListNode != null)
            {
                int _layer, _z, _fh;
                foreach (Wz_Node layerNode in fhListNode.Nodes)
                {
                    Int32.TryParse(layerNode.Text, out _layer);
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

                            FootHold footHold = new FootHold
                            {
                                X1 = x1.GetValueEx<int>(0),
                                X2 = x2.GetValueEx<int>(0),
                                Y1 = y1.GetValueEx<int>(0),
                                Y2 = y2.GetValueEx<int>(0),
                                Prev = prev.GetValueEx<int>(0),
                                Next = next.GetValueEx<int>(0),
                                Piece = piece.GetValueEx<int>(0),
                                // Name = string.Format("foothold_{0}", fhNode.Text)
                            };
                            // Console.Write("");
                            mapFootHold.Foothold.Add(footHold);
                            // mapFootHold.Add(patch);
                        }
                    }
                }
            }

            Wz_Node info = mapImgNode.FindNodeByPath("info");
            if (info != null)
            {
                Wz_Node left = info.FindNodeByPath("VRLeft"),
                    top = info.FindNodeByPath("VRTop"),
                    right = info.FindNodeByPath("VRRight"),
                    bottom = info.FindNodeByPath("VRBottom"),
                    bgm = info.FindNodeByPath("bgm"),
                    link = info.FindNodeByPath("link"),
                    mapMark = info.FindNodeByPath("mapMark");

                // load sound
                string bgmPath = null;

                if (bgm != null)
                {
                    bgmPath = bgm.GetValueEx<string>(null);
                }

                var mapMarks = mapMark.GetValueEx<string>(null);
                MapInfo mapInfo = new MapInfo
                {
                    Vrleft = left.GetValue<int>(),
                    Vrtop = top.GetValue<int>(),
                    Vrright = right.GetValue<int>(),
                    Vrbottom = top.GetValue<int>(),
                    Bgm = bgmPath,
                };
                mapImg.Info = mapInfo;
            }
            Wz_Node lifeRootNode = mapImgNode.FindNodeByPath("life");
            if (lifeRootNode != null)
            {
                foreach (var lifeNode in lifeRootNode.Nodes)
                {
                    MapLife mapLife = new MapLife()
                    {
                        Id = lifeNode.FindNodeByPath("id").GetValueEx<int>(0),
                        Type = lifeNode.FindNodeByPath("type").GetValue<string>(),
                        X = lifeNode.FindNodeByPath("x").GetValueEx<int>(0),
                        Y = lifeNode.FindNodeByPath("y").GetValueEx<int>(0),
                        Fh = lifeNode.FindNodeByPath("cy").GetValueEx<int>(0),
                        Cy = lifeNode.FindNodeByPath("rx").GetValueEx<int>(0),
                        Rx0 = lifeNode.FindNodeByPath("ry").GetValueEx<int>(0),
                        Rx1 = lifeNode.FindNodeByPath("a").GetValueEx<int>(0),
                        F = lifeNode.FindNodeByPath("f").GetValueEx<int>(0),
                    };
                    mapImg.Life.Add(mapLife);
                }
            }

            // Save map manifest file


            var output = File.Create("john.dat");

            mapImg.WriteTo(output);
            // p.Buf=ResourceList[0];

        }
        finally
        {
            wzs.Clear();
        }
    }


    static Sprite LoadSprite(Wz_Node pngNode)
    {
        // resolve uol
        pngNode = pngNode.ResolveUol();
        // resolve link
        var linkedPngNode = GetLinkedSourceNode(pngNode) ?? pngNode;
        var png = linkedPngNode.GetValue<Wz_Png>() ?? throw new Exception($"{pngNode.FullPathToFile} is not a PNG node");
        var origin = pngNode.FindNodeByPath("origin").GetValueEx<Wz_Vector>(null);
        var sprite = new Sprite()
        {
            Width = png.Width,
            Height = png.Height,
            Originx = origin?.X ?? 0,
            Originy = origin?.Y ?? 0,
            Z = pngNode.FindNodeByPath("z").GetValueEx<int>(0),
            Resource = ByteString.CopyFrom(SavePngFile(linkedPngNode)),
        };
        return sprite;
    }

    static Frame LoadFrame(Wz_Node pngNode)
    {
        // resolve uol
        pngNode = pngNode.ResolveUol();
        // resolve link
        var linkedPngNode = GetLinkedSourceNode(pngNode) ?? pngNode;
        var png = linkedPngNode.GetValue<Wz_Png>() ?? throw new Exception($"{pngNode.FullPathToFile} is not a PNG node");
        var origin = pngNode.FindNodeByPath("origin").GetValueEx<Wz_Vector>(null);
        var sprite = new Sprite()
        {
            Width = png.Width,
            Height = png.Height,
            Originx = origin?.X ?? 0,
            Originy = origin?.Y ?? 0,
            Z = pngNode.FindNodeByPath("z").GetValueEx<int>(0),
            Resource = ByteString.CopyFrom(SavePngFile(linkedPngNode)),
        };
        Frame frame = new Frame()
        {
            Sprite = sprite,
            Delay = pngNode.FindNodeByPath("delay").GetValueEx<int>(100),
            A0 = pngNode.FindNodeByPath("a0").GetValueEx<int>(255),
            A1 = pngNode.FindNodeByPath("a1").GetValueEx<int>(255),
        };
        return frame;
    }

    // You can define other methods, fields, classes and namespaces here
    static Sprite LoadSprite(Wz_Structure wzs, string resourceUrl)
    {
        var pngNode = wzs.WzNode.FindNodeByPath(true, resourceUrl.Split('/')) ?? throw new Exception("Failed to find sprite " + resourceUrl);

        // resolve uol
        pngNode = pngNode.ResolveUol();
        // resolve link
        var linkedPngNode = GetLinkedSourceNode(pngNode) ?? pngNode;
        var png = linkedPngNode.GetValue<Wz_Png>() ?? throw new Exception($"{pngNode.FullPathToFile} is not a PNG node");
        var origin = pngNode.FindNodeByPath("origin").GetValueEx<Wz_Vector>(null);
        var sprite = new Sprite()
        {
            Width = png.Width,
            Height = png.Height,
            Originx = origin?.X ?? 0,
            Originy = origin?.Y ?? 0,
            Z = pngNode.FindNodeByPath("z").GetValueEx<int>(0),
            Resource = ByteString.CopyFrom(SavePngFile(linkedPngNode)),
        };
        return sprite;
    }

    static Frame LoadFrame(Wz_Structure wzs, string resourceUrl)
    {
        var pngNode = wzs.WzNode.FindNodeByPath(true, resourceUrl.Split('/')) ?? throw new Exception("Failed to find sprite " + resourceUrl);
        // resolve uol
        pngNode = pngNode.ResolveUol();
        // resolve link
        var linkedPngNode = GetLinkedSourceNode(pngNode) ?? pngNode;
        var png = linkedPngNode.GetValue<Wz_Png>() ?? throw new Exception($"{pngNode.FullPathToFile} is not a PNG node");
        var origin = pngNode.FindNodeByPath("origin").GetValueEx<Wz_Vector>(null);
        var sprite = new Sprite()
        {
            Width = png.Width,
            Height = png.Height,
            Originx = origin?.X ?? 0,
            Originy = origin?.Y ?? 0,
            Z = pngNode.FindNodeByPath("z").GetValueEx<int>(0),
            Resource = ByteString.CopyFrom(SavePngFile(linkedPngNode)),
        };
        Frame frame = new Frame()
        {
            Sprite = sprite,
            Delay = pngNode.FindNodeByPath("delay").GetValueEx<int>(100),
            A0 = pngNode.FindNodeByPath("a0").GetValueEx<int>(255),
            A1 = pngNode.FindNodeByPath("a1").GetValueEx<int>(255),
        };
        return frame;
    }

    static Byte[] SavePngFile(Wz_Node pngNode)
    {
        ;
        using var bitmap = pngNode.GetValue<Wz_Png>().ExtractPng();
        System.IO.MemoryStream ms = new MemoryStream();
        bitmap.Save(ms, ImageFormat.Png);
        return ms.ToArray();
    }

    static FrameAnimate LoadAnimation(Wz_Structure wzs, string resourceUrl)
    {
        var aniNode = wzs.WzNode.FindNodeByPath(true, resourceUrl.Split('/')) ?? throw new Exception("Failed to find ani " + resourceUrl);
        FrameAnimate frameAnimate = new FrameAnimate();
        for (int f = 0; ; f++)
        {
            var pngNode = aniNode.FindNodeByPath(f.ToString());
            if (pngNode == null) break;
            var frame = LoadFrame(pngNode);
            frameAnimate.Frames.Add(frame);
        }
        return frameAnimate;
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

    // class MapImg
    // {
    //     public int ID { get; set; }
    //     public MapLayer[] Layers { get; } = Enumerable.Range(0, 8).Select(_ => new MapLayer()).ToArray();
    //     public MapBack[] Backs { get; set; }
    //     public FootholdPatch[] FootHold { get; set; }

    //     public MapInfo Infos { get; set; }
    //     public MapLife[] Lifes { get; set; }


    // }


    // class MapLife
    // {
    //     public int ID { get; set; }
    //     public string Type { get; set; }
    //     public int X { get; set; }
    //     public int Y { get; set; }
    //     public int Fh { get; set; }
    //     public int Cy { get; set; }
    //     public int Rx0 { get; set; }
    //     public int Rx1 { get; set; }
    //     public int F { get; set; }
    // }
    // class MapInfo
    // {
    //     public int? ID { get; set; }
    //     public string Name { get; set; }
    //     public int? Link { get; set; }
    //     public int VRLeft { get; set; }
    //     public int VRTop { get; set; }
    //     public int VRRight { get; set; }
    //     public int VRBottom { get; set; }
    //     public string MapMark { get; set; }
    //     public string Bgm { get; set; }

    //     public bool IsTown { get; set; }
    //     public bool CanFly { get; set; }
    //     public bool CanSwim { get; set; }
    //     public int? ReturnMap { get; set; }
    //     public bool HideMinimap { get; set; }
    //     public int FieldLimit { get; set; }
    // }


    // class MapLayer
    // {
    //     public List<MapTile> Tiles { get; set; }
    //     public List<MapObj> Objs { get; set; }
    // }

    // class MapTile
    // {
    //     public int ID { get; set; }
    //     public int X { get; set; }
    //     public int Y { get; set; }
    //     public Sprite Resource { get; set; }
    // }

    // class MapObj
    // {
    //     public int ID { get; set; }
    //     public int X { get; set; }
    //     public int Y { get; set; }
    //     public int Z { get; set; }
    //     public bool FlipX { get; set; }
    //     public FrameAnimate Resource { get; set; }
    // }

    // class MapBack
    // {
    //     public int ID { get; set; }
    //     public int X { get; set; }
    //     public int Y { get; set; }
    //     public int Cx { get; set; }
    //     public int Cy { get; set; }
    //     public int Rx { get; set; }
    //     public int Ry { get; set; }
    //     public int Alpha { get; set; }
    //     public bool FlipX { get; set; }
    //     public bool Front { get; set; }
    //     public int Ani { get; set; }
    //     public int Type { get; set; }
    //     public object Resource { get; set; }
    // }

    // //--------------------------------------


    // class FootholdPatch
    // {
    //     public int X1 { get; set; }
    //     public int Y1 { get; set; }
    //     public int X2 { get; set; }
    //     public int Y2 { get; set; }
    //     public int Prev { get; set; }
    //     public int Next { get; set; }
    //     public int Piece { get; set; }
    //     // public string Name { get; internal set; }
    //     public int ID { get; internal set; }
    //     public int Layer { get; internal set; }
    // }

    // class Sprite
    // {
    //     public int Width { get; set; }
    //     public int Height { get; set; }
    //     public int OriginX { get; set; }
    //     public int OriginY { get; set; }
    //     public int Z { get; set; }
    //     public int ResourceUrl { get; set; }
    // }

    // class Frame : Sprite
    // {
    //     public int Delay { get; set; }
    //     public int A0 { get; set; }
    //     public int A1 { get; set; }
    // }

    // class FrameAnimate
    // {
    //     public List<Frame> Frames { get; set; }
    // }
}
