float4x4    mtxWorldViewProj;   // World * View * Projectionマトリックス

// 行列パレット
/*
#if ( MODE_VS_2_X || MODE_VP40 )
    #define S_VERTEX_BLEND_BONE_MAX     64  // 頂点ブレンドの骨の最大数
#else
    #define S_VERTEX_BLEND_BONE_MAX     20  // 頂点ブレンドの骨の最大数
#endif
//*/
#define S_VERTEX_BLEND_BONE_MAX     64  // 頂点ブレンドの骨の最大数
uniform float4      aVertexBlend[ S_VERTEX_BLEND_BONE_MAX * 3 ];    // 頂点ブレンドの骨の最大数

// 出力構造体
struct VS_INPUT
{
    float4  Position    : POSITION;     // 位置

#if CV_ENABLE_COLOR_MAP
    #if !CV_USE_2ND_UV
        float2  TexCoord0   : TEXCOORD0;
    #else
        float2  TexCoord1   : TEXCOORD1;
    #endif
#endif

#if CV_ENABLE_2BONE_SKINNING
    float4  Weight0     : ATTR1;  // ブレンドウェイト0&1
#endif
};


// 入力構造体
struct VS_OUTPUT
{
    float4  Position    : POSITION;       // 位置
    float4  f4UV        : TEXCOORD0;
};


//-----------------------------------------------------------------------------
/// @brief 頂点ブレンド変換(weight2)
///
/// 位置と法線に対してスキニングを行います。
/// ウェイト情報はfloat4に入ってきます。
/// データの格納順番は以下の通りです。
///
/// Weight[0]   [w0][t0][w1][t1]
///
/// 頂点バッファには_sColor8として入っているので、
/// インデックス情報は255倍する必要があります。
///
/// @param _Position 位置(ローカル座標)
/// @param _Weight ウェイト(格納データはコメント参照)
/// @param _outPosition 出力位置(ローカル座標)
//-----------------------------------------------------------------------------
// スキニング計算   
void    getTransformPositionSkinning2(
        float4  _Position,
        float4  _Weight0,
    out float4  _outPosition)
{
    // インデックス
    int4    Index   = { 
        _Weight0.y * 255.01 * 3,
        _Weight0.w * 255.01 * 3,        
        0.0f,
        0.0f };

#ifdef  MODE_DXPC
    // ウェイト
    float4  Weight  = {
        _Weight0.x,
        _Weight0.z,
        0.0f,
        0.0f };
#else
    // GL版は XYZW -> ZYXW になる
    // ウェイト
    float4  Weight  = {
        _Weight0.z,
        _Weight0.x,
        0.0f,
        0.0f };
#endif

    // 位置
    _outPosition.xyzw   = float4( 0.0f, 0.0f, 0.0f, 1.0f );
    
    for( int i=0; i<2; i++ ) {      

        _outPosition.x  += dot( _Position, aVertexBlend[ Index[i] + 0 ] ) * Weight[i];
        _outPosition.y  += dot( _Position, aVertexBlend[ Index[i] + 1 ] ) * Weight[i];
        _outPosition.z  += dot( _Position, aVertexBlend[ Index[i] + 2 ] ) * Weight[i];
    }
}


//-----------------------------------------------------------------------------
// main
//-----------------------------------------------------------------------------
VS_OUTPUT main(VS_INPUT _Input)
{
    VS_OUTPUT Output    = (VS_OUTPUT)0; // 出力データ

    // ---------------------------------------------------------------------------------------------------------------
    // 座標変換を行う
    // ---------------------------------------------------------------------------------------------------------------
    
    #if CV_ENABLE_2BONE_SKINNING
        // 2 ボーンスキニング処理を行う
        float4 f4LocalPosition  = 0.0f;
        getTransformPositionSkinning2(
            _Input.Position,
            _Input.Weight0,
            f4LocalPosition);
        Output.Position = mul(mtxWorldViewProj, f4LocalPosition);
    #else   
        Output.Position = mul(mtxWorldViewProj, _Input.Position);
    #endif
    
    // ---------------------------------------------------------------------------------------------------------------
    // 深度情報を出力する
    //  -   オーバーレイ時は z を 0 に変更する (深度情報は無視する)
    // ---------------------------------------------------------------------------------------------------------------
    
    #if CV_ENABLE_OVERLAY
        Output.Position.z   = 0.0f;
    #else
        Output.f4UV = Output.Position;  //< 通常のシャドウマップ時は UV に射影空間での頂点座標を格納しておく
    #endif

    // ---------------------------------------------------------------------------------------------------------------
    // カラーマップの UV を出力する
    // ---------------------------------------------------------------------------------------------------------------
    
    #if CV_ENABLE_COLOR_MAP
        #if CV_USE_2ND_UV
            Output.f4UV.xy  = _Input.TexCoord1.xy;  //< 投影影はUV1でフェッチすべし
        #else
            Output.f4UV.xy  = _Input.TexCoord0.xy;
        #endif
    #endif
        
    return Output;
}