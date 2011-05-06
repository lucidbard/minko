package aerys.minko.type.stream
{
	import aerys.common.IVersionnable;
	import aerys.minko.ns.minko;
	import aerys.minko.type.vertex.format.NativeFormat;
	import aerys.minko.type.vertex.format.PackedVertexFormat;
	import aerys.minko.type.vertex.format.VertexFormat;
	
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.ByteArray;
	
	
	public final class VertexStream implements IVersionnable
	{
		use namespace minko;
		
		public static const DEFAULT_FORMAT	: PackedVertexFormat	= PackedVertexFormat.XYZ_UV;
		
		minko var _data				: Vector.<Number>		= null;
		minko var _update			: Boolean				= true;
		minko var _dynamic			: Boolean				= false;
		minko var _nativeBuffer		: VertexBuffer3D		= null;
		minko var _version			: uint					= 0;
		
		private var _format			: PackedVertexFormat	= null;
		
		public function get length() 	: int					{ return _data.length / _format.dwordsPerVertex; }
		public function get format()	: PackedVertexFormat	{ return _format; }
		public function get version()	: uint					{ return _version; }
	
		public function VertexStream(data 		: Vector.<Number>,
									 format		: PackedVertexFormat	= null,
									 dynamic	: Boolean				= false)
		{
			super();

			_format = format || DEFAULT_FORMAT;
			
			if (data.length % _format.dwordsPerVertex)
 				throw new Error("Incompatible vertex format: the data length does not match");
			
			_data = data ? data.concat() : null;
			_dynamic = dynamic;
		}
		
		minko function getNativeVertexBuffer3D(context : Context3D) : VertexBuffer3D {
			
			if (!_nativeBuffer)
				_nativeBuffer = context.createVertexBuffer(length, format.dwordsPerVertex);
			
			if (_update)
			{
				_update = false;
				_nativeBuffer.uploadFromVector(_data, 0, length);
				
				if (!_dynamic)
					_data = null;
			}
			return _nativeBuffer;
		}
		
		public function deleteVertexByIndex(myIndex : int) : Boolean
		{
			if (myIndex > length)
				return false;
			
			_data.splice(myIndex, _format.dwordsPerVertex);
			_update = true;
			
			return true;
		}
		
		public static function fromPositionsAndUVs(positions : Vector.<Number>,
												   uvs		 : Vector.<Number>) : VertexStream
		{
			var numVertices : int = positions.length / 3;
			var stride : int = uvs ? 5 : 3;
			var data : Vector.<Number> = new Vector.<Number>(numVertices * stride, true);
			
			for (var i : int = 0; i < numVertices; ++i)
			{
				var offset : int = i * stride;
				
				data[offset] = positions[int(i * 3)];
				data[int(offset + 1)] = positions[int(i * 3 + 1)];
				data[int(offset + 2)] = positions[int(i * 3 + 2)];
				
				if (uvs)
				{
					data[int(offset + 3)] = uvs[int(i * 2)];
					data[int(offset + 4)] = uvs[int(i * 2 + 1)];
				}
			}
			
			return new VertexStream(data, uvs ? PackedVertexFormat.XYZ_UV : PackedVertexFormat.XYZ);
		}
		
		public static function fromByteArray(data 	: ByteArray,
											 count	: int,
											 format	: PackedVertexFormat) : VertexStream
		{
			var numFormats		: int				= format.components.length;
			var nativeFormats	: Vector.<int>		= new Vector.<int>(numFormats, true);
			var length			: int				= 0;
			var tmp				: Vector.<Number>	= null;
			var stream			: VertexStream	= new VertexStream(null, format);
			
			for (var k : int = 0; k < numFormats; k++)
				nativeFormats[k] = format.components[k].nativeFormat;
			
			stream._data = tmp;
			
			tmp = new Vector.<Number>(format.dwordsPerVertex * count,
									  true);
			
			for (var j : int = 0; j < count; ++j)
			{
				for (var i : int = 0; i < numFormats; ++i)
				{
					switch (nativeFormats[i])
					{
						case NativeFormat.FLOAT_4 :
							tmp[int(length++)] = data.readFloat();
						case NativeFormat.FLOAT_3 :
							tmp[int(length++)] = data.readFloat();
						case NativeFormat.FLOAT_2 :
							tmp[int(length++)] = data.readFloat();
						case NativeFormat.FLOAT_1 :
							tmp[int(length++)] = data.readFloat();
							break ;
					}
				}
			}
			
			return stream;
		}
		
	}
}