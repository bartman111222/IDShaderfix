#define CV_ENABLE_DEBUG


const uniform float3x4  mtxWorld;           // World�}�g���b�N�X
const uniform float3x4  mtxWorldView;       // World * View�}�g���b�N�X
const uniform float4x4  mtxWorldViewProj;   // World * View * Projection�}�g���b�N�X
const uniform float4x4  m4Local2ShadowMap;  // ���[�J����� �� �V���h�E�}�b�v�ϊ��}�g���N�X


// �s��p���b�g
#define S_VERTEX_BLEND_BONE_MAX     64  // ���_�u�����h�̍��̍ő吔
const uniform float4    aVertexBlend[ S_VERTEX_BLEND_BONE_MAX * 3 ];    // ���_�u�����h�̍��̍ő吔

struct VS_INPUT
{
    float4  Position    : POSITION;     // ���W
    float3  Normal      : NORMAL;       // �@��

#if CV_ENABLE_COLOR_MAP
    float2  TexCoord0   : TEXCOORD0;
#endif

#if CV_ENABLE_2BONE_SKINNING
    float4  Weight0     : ATTR1;  // �u�����h�E�F�C�g0&1
#endif
};


struct VS_OUTPUT
{
    float4  Position        : POSITION;     // �ʒu

#if CV_ENABLE_COLOR_MAP
    float4  f4UV_BaseMap    : TEXCOORD0;    //< �e�N�X�`��UV (xy = UV0, zw = UV1)
#endif

#if CV_ENABLE_SHADOW_MAP
    float4  f4UV_ShadowMap  : TEXCOORD1;
#endif

    float3  f3Normal        : TEXCOORD2;
    float3  f3Normal_View   : TEXCOORD3;
    float3  f3Pos_View      : TEXCOORD4;
	
#ifdef CV_ENABLE_DEBUG
	float4 f4Color : COLOR0;
#endif
};


//-----------------------------------------------------------------------------
/// @brief ���_�u�����h�ϊ�(weight2)
///
/// �ʒu�Ɩ@���ɑ΂��ăX�L�j���O���s���܂��B
/// �E�F�C�g����float4�ɓ����Ă��܂��B
/// �f�[�^�̊i�[���Ԃ͈ȉ��̒ʂ�ł��B
///
/// Weight[0]   [w0][t0][w1][t1]
///
/// ���_�o�b�t�@�ɂ�_sColor8�Ƃ��ē����Ă���̂ŁA
/// �C���f�b�N�X����255�{����K�v������܂��B
///
/// @param _Position �ʒu(���[�J�����W)
/// @param _Normal �@��(���[�J�����W)
/// @param _Weight �E�F�C�g(�i�[�f�[�^�̓R�����g�Q��)
/// @param _outPosition �o�͈ʒu(���[�J�����W)
/// @param _outNormal �o�͖@��(���[�J�����W)
//-----------------------------------------------------------------------------
// �X�L�j���O�v�Z   
void    getTransformPositionSkinning2(
        float4  _Position,
        float3  _Normal,
        float4  _Weight0,
    out float4  _outPosition,
    out float3  _outNormal )
{
    // �C���f�b�N�X
    float4  Index   = { 
        _Weight0.y * 255.01 * 3,
        _Weight0.w * 255.01 * 3,        
        0.0f,
        0.0f };

#ifdef  MODE_DXPC
    // �E�F�C�g
    float4  Weight  = {
        _Weight0.x,
        _Weight0.z,
        0.0f,
        0.0f };
#else
    // GL�ł� XYZW -> ZYXW �ɂȂ�
    // �E�F�C�g
    float4  Weight  = {
        _Weight0.z,
        _Weight0.x,
        0.0f,
        0.0f };
#endif

    // �ʒu
    _outPosition.xyzw   = float4( 0.0f, 0.0f, 0.0f, 1.0f );
    
    // �@��
    _outNormal.xyz  = float3( 0.0f, 0.0f, 0.0f );
/*
    for( int i=0; i<2; i++ ) {      

        _outPosition.x  += dot( _Position, aVertexBlend[ Index[i] + 0 ] ) * Weight[i];
        _outPosition.y  += dot( _Position, aVertexBlend[ Index[i] + 1 ] ) * Weight[i];
        _outPosition.z  += dot( _Position, aVertexBlend[ Index[i] + 2 ] ) * Weight[i];
    
        _outNormal.x    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 0 ] ) * Weight[i];
        _outNormal.y    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 1 ] ) * Weight[i];
        _outNormal.z    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 2 ] ) * Weight[i];
	}//*/

	int i = 0;
	float fWeight = Weight[i];
//	Index[i] = 17;
/*
	if(fWeight < 0.00010f){
		fWeight = 0.0f;
		Index[i] = 17;
	    _outPosition.x  += dot( _Position, aVertexBlend[ Index[i] + 0 ] ) * fWeight;
	    _outPosition.y  += dot( _Position, aVertexBlend[ Index[i] + 1 ] ) * fWeight;
	    _outPosition.z  += dot( _Position, aVertexBlend[ Index[i] + 2 ] ) * fWeight;
	    _outNormal.x    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 0 ] ) * fWeight;
	    _outNormal.y    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 1 ] ) * fWeight;
	    _outNormal.z    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 2 ] ) * fWeight;
	}
	else{//*/
	    _outPosition.x  += dot( _Position, aVertexBlend[ Index[i] + 0 ] ) * fWeight;
	    _outPosition.y  += dot( _Position, aVertexBlend[ Index[i] + 1 ] ) * fWeight;
	    _outPosition.z  += dot( _Position, aVertexBlend[ Index[i] + 2 ] ) * fWeight;
	    _outNormal.x    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 0 ] ) * fWeight;
	    _outNormal.y    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 1 ] ) * fWeight;
	    _outNormal.z    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 2 ] ) * fWeight;
//	}
	
	i = 1;
//	fWeight = 1.0f - fWeight;
	fWeight = Weight[i];
//	Index[i] = 0;
    _outPosition.x  += dot( _Position, aVertexBlend[ Index[i] + 0 ] ) * fWeight;
    _outPosition.y  += dot( _Position, aVertexBlend[ Index[i] + 1 ] ) * fWeight;
    _outPosition.z  += dot( _Position, aVertexBlend[ Index[i] + 2 ] ) * fWeight;
    _outNormal.x    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 0 ] ) * fWeight;
    _outNormal.y    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 1 ] ) * fWeight;
    _outNormal.z    += dot( _Normal, (float3)aVertexBlend[ Index[i] + 2 ] ) * fWeight;//*/
}

//-----------------------------------------------------------------------------
// main
//-----------------------------------------------------------------------------
VS_OUTPUT main(VS_INPUT _Input)
{
    VS_OUTPUT Output = (VS_OUTPUT)0;    // �o�̓f�[�^

    // ---------------------------------------------------------------------------------------------------------------
    // ���W�ϊ�
    // ---------------------------------------------------------------------------------------------------------------

    #if CV_ENABLE_2BONE_SKINNING
        // 2 �{�[���X�L�j���O�������s��
        float4 f4LocalPosition  = 0.0f;
        float3 f3LocalNormal    = 0.0f;
        getTransformPositionSkinning2(
            _Input.Position,
            _Input.Normal,
            _Input.Weight0,
            f4LocalPosition,
            f3LocalNormal);
    #else
        float4 f4LocalPosition  = _Input.Position;
        float3 f3LocalNormal    = _Input.Normal;
    #endif

#ifdef CV_ENABLE_DEBUG
#if CV_ENABLE_2BONE_SKINNING
/*
        f4LocalPosition  = _Input.Position;
        f3LocalNormal    = _Input.Normal;
		
		float fCenter = 1.0f / 255.0f;
		float fWidth = 0.010f / 255.0f;
		Output.f4Color = (fCenter - fWidth < _Input.Weight0.w && _Input.Weight0.w < fCenter + fWidth) ? float4(1.0f, 1.0f, 1.0f, 1.0f) : float4(1.0f, 0.0f, 0.0f, 0.0f);
//*/		
	//Output.f4Color = _Input.Weight0;
	//Output.f4Color = 0.0f < _Input.Weight0.z ? half4(1.0h, 1.0h, 1.0h, 1.0h) : _Input.Weight0;
#endif
#endif

//    f4LocalPosition = _Input.Position;
//    f4LocalPosition.w = 1.0f;

    Output.Position         = mul(mtxWorldViewProj, f4LocalPosition);
    Output.f3Pos_View       = mul(mtxWorldView, f4LocalPosition);

    // ---------------------------------------------------------------------------------------------------------------
    // ���C�e�B���O
    // ---------------------------------------------------------------------------------------------------------------

    Output.f3Normal         = mul((float3x3)mtxWorld, f3LocalNormal);
    Output.f3Normal_View    = mul((float3x3)mtxWorldView, f3LocalNormal);

    // ---------------------------------------------------------------------------------------------------------------
    // UV
    // ---------------------------------------------------------------------------------------------------------------

    #if CV_ENABLE_COLOR_MAP
        Output.f4UV_BaseMap.xy  = _Input.TexCoord0;
    #endif

    #if CV_ENABLE_SHADOW_MAP
        Output.f4UV_ShadowMap   = mul(m4Local2ShadowMap, f4LocalPosition);
    #endif

    return Output;
}

