float4x4    mtxWorldViewProj;   //< World * View * Projectionマトリックス
float4      f4CameraPos;        //< xyz: ワールド空間でのカメラ位置, w: 未使用
float4      f4ObjectCenter;     //< zw: ラインの太さ (射影空間での太さであるため、アスペクト比も含めること)
float3      f3LocalCameraPos;   //< ローカル空間でのカメラ位置

//	行列パレット
#define S_VERTEX_BLEND_BONE_MAX     64  // 頂点ブレンドの骨の最大数
uniform float4      aVertexBlend[ S_VERTEX_BLEND_BONE_MAX * 3 ];    // 頂点ブレンドの骨の最大数

struct VS_INPUT
{
    float4  Position    : POSITION;	// 座標0 (w = 1.0f が代入されるものとする)
    float4  Normal      : NORMAL;	// 座標1 (w = 1.0f が代入されるものとする)
    float4  Binormal    : BINORMAL;	// 座標2 (w = 1.0f が代入されるものとする)
    float4  Tangent     : TANGENT;	// 座標3 (w = 1.0f が代入されるものとする)
#if CV_ELIMINATE_OVERDRAW || CV_START_CAP || CV_FINISH_CAP
    float3  TexCoord0   : TEXCOORD0;	// 法線0
    float3  TexCoord1   : TEXCOORD1;	// 法線1
	#if CV_ENABLE_2BONE_SKINNING
		float4  TexCoord2   : TEXCOORD2;    // 行列インデックス0
		float4  TexCoord3   : TEXCOORD3;    // 行列インデックス1
		float4  Weight0     : ATTR1;  // ブレンドウェイト0&1
	#endif
#else
	#if CV_ENABLE_2BONE_SKINNING
		float4  TexCoord2   : TEXCOORD0;    // 行列インデックス0
		float4  TexCoord3   : TEXCOORD1;    // 行列インデックス1
		float4  Weight0     : ATTR1;  // ブレンドウェイト0&1
	#endif
#endif
    float4  Color       : COLOR0;       // カラー
};

struct VS_OUTPUT
{
    float4  f4Position  : POSITION;
    float4  f2UV0       : TEXCOORD0;
    float4	f4Color     : COLOR0;	//< test060626
};


//-----------------------------------------------------------------------------
// 頂点カラーの r, b を入れ替える
// 頂点バッファを書き換えといたほうがいいと思うが
//-----------------------------------------------------------------------------

float4 S_RGB(float4 _Color)
{
#ifdef MODE_DXPC
    return _Color;
#else
    return _Color.zyxw;
#endif
}


/// @param  _Position       入力ローカル座標
/// @param  fMatrixIndex0   行列インデックス0   (255.01 * 3 倍されていること)
/// @param  fMatrixIndex1   行列インデックス1   (255.01 * 3 倍されていること)
/// @param  fWeight0        ボーン 0 に対するウエイト
/// @param  _outPosition    出力ローカル座標
void getTransformPositionSkinning2_Optimized(
        float4  _Position,
        float   fMatrixIndex0,
        float   fMatrixIndex1,
        float   fWeight0,
    out float4  _outPosition)
{
    float3x4 f34LocalMatrix;
    f34LocalMatrix[0] = aVertexBlend[fMatrixIndex0 + 0].xyzw;
    f34LocalMatrix[1] = aVertexBlend[fMatrixIndex0 + 1].xyzw;
    f34LocalMatrix[2] = aVertexBlend[fMatrixIndex0 + 2].xyzw;
    float3 f3PosA = mul(f34LocalMatrix, _Position.xyzw);

    f34LocalMatrix[0] = aVertexBlend[fMatrixIndex1 + 0].xyzw;
    f34LocalMatrix[1] = aVertexBlend[fMatrixIndex1 + 1].xyzw;
    f34LocalMatrix[2] = aVertexBlend[fMatrixIndex1 + 2].xyzw;
    float3 f3PosB = mul(f34LocalMatrix, _Position.xyzw);

    _outPosition.xyz = lerp(f3PosB, f3PosA, fWeight0);
    _outPosition.w   = 1.0f;
}


//-----------------------------------------------------------------------------
// main
//-----------------------------------------------------------------------------
VS_OUTPUT main(
    VS_INPUT _Input)
{
    VS_OUTPUT Output = (VS_OUTPUT)0;

    float4 f4Pos0 = _Input.Position;
    float4 f4Pos1 = _Input.Normal;
    float4 f4Pos2 = _Input.Binormal;
    float4 f4Pos3 = _Input.Tangent;
    const float fRefIndex = _Input.Color.x;	//< UBYTE4 なので DX/GL 間でバイトの並びは変わりません。また、値の範囲は 0 ~ 255 の模様です
    const float fEdgeFlag = _Input.Color.y;

#if CV_ENABLE_2BONE_SKINNING
    //	頂点を 2 bone skinning する
//#ifdef MODE_DXPC
#if 0
    const float4 f4MatrixIndex0 = (int4)(_Input.TexCoord2.wzyx * 3.0f);	//< 行列インデックスが入れ替わっているのを考慮してみた
    const float4 f4MatrixIndex1 = (int4)(_Input.TexCoord3.wzyx * 3.0f);
    const float4 f4Weight0 = _Input.Weight0.wzyx / 255.0f;
#else
    const float4 f4MatrixIndex0 = _Input.TexCoord2.wzyx * 3.0f;	//< 行列インデックスが入れ替わっているのを考慮してみた
    const float4 f4MatrixIndex1 = _Input.TexCoord3.wzyx * 3.0f;
    const float4 f4Weight0 = _Input.Weight0.wzyx / 255.0f;
#endif
    getTransformPositionSkinning2_Optimized(f4Pos0.xyzw, f4MatrixIndex0.x, f4MatrixIndex1.x, f4Weight0.x, f4Pos0.xyzw);
    getTransformPositionSkinning2_Optimized(f4Pos1.xyzw, f4MatrixIndex0.y, f4MatrixIndex1.y, f4Weight0.y, f4Pos1.xyzw);
    getTransformPositionSkinning2_Optimized(f4Pos2.xyzw, f4MatrixIndex0.z, f4MatrixIndex1.z, f4Weight0.z, f4Pos2.xyzw);
    getTransformPositionSkinning2_Optimized(f4Pos3.xyzw, f4MatrixIndex0.w, f4MatrixIndex1.w, f4Weight0.w, f4Pos3.xyzw);
#endif

    // ローカル空間での面法線を求める
    float3 f3N_A = cross(f4Pos2.xyz - f4Pos0.xyz, f4Pos1.xyz - f4Pos0.xyz); //< 正規化しなくてよい。内積の符号が分かればいいから。
    float3 f3N_B = cross(f4Pos1.xyz - f4Pos0.xyz, f4Pos3.xyz - f4Pos0.xyz); //< 正規化しなくてよい。内積の符号が分かればいいから。

    // ローカル空間での視線ベクトルを求める
    float3 f3Camera2Pos0 = f3LocalCameraPos - f4Pos0.xyz;   //< 正規化しなくてよい。内積の符号が分かればいいから。

    // 輪郭として描画するか調べる
    bool fContour   = dot(f3N_A, f3Camera2Pos0) * dot(f3N_B, f3Camera2Pos0) < 0.0f;
    bool fBoundary  = fEdgeFlag > 0.0f; // f3V_0 == f3V_3 だったら、成立する

	if(fContour || fBoundary){
//	if(fBoundary){
//	if(true){
        //	射影空間での w 除算済みの頂点座標を求める
		f4Pos0.w = 1.0f;
		f4Pos1.w = 1.0f;
		
        float4 f4V0 = mul((float4x4)mtxWorldViewProj, f4Pos0.xyzw);
        float4 f4V1 = mul((float4x4)mtxWorldViewProj, f4Pos1.xyzw);
/*
		{
			float2 f2S0 = f4V0.xy / f4V0.w;
			float2 f2S1 = f4V1.xy / f4V1.w;
			if((f2S0.y - f2S1.y) * (f2S0.y - f2S1.y) < (f2S1.x - f2S0.x) * (f2S1.x - f2S0.x)){
				// test
				if(f4V0.x / f4V0.w < f4V1.x / f4V1.w){
					float4 f4Temp = f4V0; 
					f4V0 = f4V1;
					f4V1 = f4Temp;
				}
			}
			else{
				// test
				if(f4V1.y / f4V0.w < f4V0.y / f4V1.w){
					float4 f4Temp = f4V0; 
					f4V0 = f4V1;
					f4V1 = f4Temp;
				}
			}
		}
//*/
        float2 f2S0 = f4V0.xy / f4V0.w;
        float2 f2S1 = f4V1.xy / f4V1.w;

        //	エッジに垂直なベクトルを求める
		float4 f4P = float4(f2S0.y - f2S1.y, f2S1.x - f2S0.x, 0.0f, 0.0f);
		f4P.xy *= f4ObjectCenter.zw;	//< ベクトル自体にアスペクト比を反映させる (正規化前にする必要がある)
		f4P.xy = normalize(f4P.xy) * f4ObjectCenter.zw;   //< 太さ

		//	法線を求める
#if CV_ELIMINATE_OVERDRAW || CV_START_CAP
		float4 f4OutsidePos0 = _Input.Position;//f4Pos0.xyzw;
		f4OutsidePos0.xyz += _Input.TexCoord0.xyz;
	#if CV_ENABLE_2BONE_SKINNING
			getTransformPositionSkinning2_Optimized(f4OutsidePos0, f4MatrixIndex0.x, f4MatrixIndex1.x, f4Weight0.x, f4OutsidePos0);
	#endif
		float4 f4OutsidePos0Proj = mul((float4x4)mtxWorldViewProj, f4OutsidePos0.xyzw);
		float2 f2M0 = f4OutsidePos0Proj.xy / f4OutsidePos0Proj.w - f2S0;
		f2M0.xy *= f4ObjectCenter.wz;	//< ベクトル自体にアスペクト比を反映させる (正規化前にする必要がある)
	#if CV_START_CAP
			f2M0.xy = normalize(f2M0.xy) * f4ObjectCenter.zw;   //< 太さ
	#endif
#elif CV_FINISH_CAP
		float4 f4OutsidePos1 = _Input.Normal;//f4Pos1.xyzw;
		f4OutsidePos1.xyz += _Input.TexCoord1.xyz;
	#if CV_ENABLE_2BONE_SKINNING
			getTransformPositionSkinning2_Optimized(f4OutsidePos1, f4MatrixIndex0.x, f4MatrixIndex1.x, f4Weight0.x, f4OutsidePos1);
	#endif
		float4 f4OutsidePos1Proj = mul((float4x4)mtxWorldViewProj, f4OutsidePos1.xyzw);
		float2 f2M1 = f4OutsidePos1Proj.xy / f4OutsidePos1Proj.w - f2S1;
		f2M1.xy *= f4ObjectCenter.wz;	//< ベクトル自体にアスペクト比を反映させる (正規化前にする必要がある)
		f2M1.xy = normalize(f2M1.xy) * f4ObjectCenter.zw;   //< 太さ
#endif

		// test060626
		//f4P *= 10.0f;
/*
        if(fRefIndex > 2.0f){
            // outside, end
            Output.f4Position = f4V1 + f4P * f4V1.w;
            Output.f2UV0.x = 1.0f;
        }
        else if(fRefIndex > 1.0f){
            // outside, start
            Output.f4Position = f4V0 + f4P * f4V0.w;
            Output.f2UV0.x = 1.0f;
        }
        else if(fRefIndex > 0.0f){
            // inside, end
            Output.f4Position = f4V1 - f4P * f4V1.w;
        //  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
        }
        else{
            // inside, start
            Output.f4Position = f4V0 - f4P * f4V0.w;
//			Output.f4Position.z = 0.50f;	//< test
        //  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
        }
/*/




#if CV_ELIMINATE_OVERDRAW
		if(2.0f < fRefIndex){
			//	outside, start
			Output.f4Position.xyzw = f4V0.xyzw;
		//	Output.f4Position.xyzw += (0.0f < dot(f4P.xy, f2M0)) ? f4P.xyzw * f4V0.wwww : - f4P.xyzw * f4V0.wwww;
			Output.f4Position.xy += (0.0f < dot(f4P.xy, f2M0)) ? f4P.xy * f4V0.ww : - f4P.xy * f4V0.ww;
			Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(0.0f, 1.0f, 0.0f, 1.0f);	//< test
		}
		else if(1.0f < fRefIndex){
			//	outside, end
			Output.f4Position.xyzw = f4V1.xyzw;
			Output.f4Position.xyzw += (0.0f < dot(f4P.xy, f2M0)) ? f4P.xyzw * f4V1.wwww : - f4P.xyzw * f4V1.wwww;
			Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(1.0f, 0.0f, 0.0f, 1.0f);	//< test
		}
		else if(0.0f < fRefIndex){
			//	inside, end
			Output.f4Position.xyzw = f4V1.xyzw;
		//  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
			Output.f4Color = float4(0.0f, 0.0f, 1.0f, 1.0f);	//< test
		}
		else{
			//	inside, start
			Output.f4Position.xyzw = f4V0.xyzw;
		//  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
			Output.f4Color = float4(1.0f, 1.0f, 0.0f, 1.0f);	//< test
		}
#elif CV_START_CAP
		if(1.0f < fRefIndex){
			//	outside, normal
			Output.f4Position.xyzw = f4V0.xyzw;
			Output.f4Position.xy += f2M0 * f4V0.ww;
			//Output.f4Position.xy += normalize(f4OutsidePos0Proj.xy - f4V0.xy) * 0.10f * f4V0.ww;//*/
//			Output.f4Position = f4OutsidePos0Proj;
			Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(1.0f, 0.0f, 1.0f, 1.0f);	//< test
		}
		else if(0.0f < fRefIndex){
			//	outside, start
			Output.f4Position.xyzw = f4V0.xyzw;
			Output.f4Position.xyzw += (0.0f < dot(f4P.xy, f2M0)) ? f4P.xyzw * f4V0.wwww : - f4P.xyzw * f4V0.wwww;
			Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(0.0f, 0.0f, 1.0f, 1.0f);	//< test
		}
		else{
			//	inside, start
			Output.f4Position.xyzw = f4V0.xyzw;
		//  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
			Output.f4Color = float4(1.0f, 1.0f, 0.0f, 1.0f);	//< test
		}
#elif CV_FINISH_CAP
		if(1.0f < fRefIndex){
			//	outside, normal
			Output.f4Position.xyzw = f4V1.xyzw;
			Output.f4Position.xy += f2M1 * f4V1.ww;
			Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(1.0f, 0.0f, 1.0f, 1.0f);	//< test
		}
		else if(0.0f < fRefIndex){
			//	outside, start
			Output.f4Position.xyzw = f4V1.xyzw;
			Output.f4Position.xyzw += (0.0f < dot(f4P.xy, f2M1)) ? f4P.xyzw * f4V1.wwww : - f4P.xyzw * f4V1.wwww;
			Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(1.0f, 0.0f, 0.0f, 1.0f);	//< test
		}
		else{
			//	inside, start
			Output.f4Position.xyzw = f4V1.xyzw;
		//  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
			Output.f4Color = float4(1.0f, 1.0f, 0.0f, 1.0f);	//< test
		}
#else
		if(2.0f < fRefIndex){
			//	outside, start
			Output.f4Position.xyzw = f4V0.xyzw + f4P.xyzw * f4V0.wwww;
            Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(0.0f, 1.0f, 0.0f, 1.0f);	//< test
		}
		else if(1.0f < fRefIndex){
			//	outside, end
			Output.f4Position.xyzw = f4V1.xyzw + f4P.xyzw * f4V1.wwww;
			Output.f2UV0.x = 1.0f;	//< これは必要
			Output.f4Color = float4(1.0f, 0.0f, 0.0f, 1.0f);	//< test
		}
		else if(0.0f < fRefIndex){
			//	inside, end
			Output.f4Position.xyzw = f4V1.xyzw - f4P.xyzw * f4V1.wwww;
		//  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
			Output.f4Color = float4(0.0f, 0.0f, 1.0f, 1.0f);	//< test
		}
		else{
			//	inside, start
			Output.f4Position.xyzw = f4V0.xyzw - f4P.xyzw * f4V0.wwww;
		//  Output.f2UV0.x = 0.0f;  //< 既に0を代入済みのため無視する
			Output.f4Color = float4(1.0f, 1.0f, 0.0f, 1.0f);	//< test
		}
#endif


		//	ストロークテクスチャの V を求める
		float2 f2UV_Y = (Output.f4Position.xy / Output.f4Position.ww - f4ObjectCenter.xy);
		//Output.f2UV0.y = abs(f4V1.x - f4V0.x) < abs(f4V1.y - f4V0.y) ? f2UV_Y.y : f2UV_Y.x;
		
		// test
		//Output.f2UV0.y = (abs(f4P.y) < abs(f4P.x)) ? f2UV_Y.y : f2UV_Y.x;
		Output.f2UV0.yz = f2UV_Y;
		
		//Output.f2UV0.y = f2UV_Y;
		Output.f4Color.a = abs(f4P.y) / abs(f4P.x + 0.0000010f);	//< test
		
    }
    else{
        // 描画しない場合は、z を負にする
        Output.f4Position = float4(0.0f, 0.0f, -10.0f, 1.0f);
    }

    return Output;
}

