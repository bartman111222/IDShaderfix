float4x4    mtxWorldViewProj;   // World * View * Projection�}�g���b�N�X

// �s��p���b�g
/*
#if ( MODE_VS_2_X || MODE_VP40 )
    #define S_VERTEX_BLEND_BONE_MAX     64  // ���_�u�����h�̍��̍ő吔
#else
    #define S_VERTEX_BLEND_BONE_MAX     20  // ���_�u�����h�̍��̍ő吔
#endif
//*/
#define S_VERTEX_BLEND_BONE_MAX     64  // ���_�u�����h�̍��̍ő吔
uniform float4      aVertexBlend[ S_VERTEX_BLEND_BONE_MAX * 3 ];    // ���_�u�����h�̍��̍ő吔

// �o�͍\����
struct VS_INPUT
{
    float4  Position    : POSITION;     // �ʒu

#if CV_ENABLE_COLOR_MAP
    #if !CV_USE_2ND_UV
        float2  TexCoord0   : TEXCOORD0;
    #else
        float2  TexCoord1   : TEXCOORD1;
    #endif
#endif

#if CV_ENABLE_2BONE_SKINNING
    float4  Weight0     : ATTR1;  // �u�����h�E�F�C�g0&1
#endif
};


// ���͍\����
struct VS_OUTPUT
{
    float4  Position    : POSITION;       // �ʒu
    float4  f4UV        : TEXCOORD0;
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
/// @param _Weight �E�F�C�g(�i�[�f�[�^�̓R�����g�Q��)
/// @param _outPosition �o�͈ʒu(���[�J�����W)
//-----------------------------------------------------------------------------
// �X�L�j���O�v�Z   
void    getTransformPositionSkinning2(
        float4  _Position,
        float4  _Weight0,
    out float4  _outPosition)
{
    // �C���f�b�N�X
    int4    Index   = { 
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
    VS_OUTPUT Output    = (VS_OUTPUT)0; // �o�̓f�[�^

    // ---------------------------------------------------------------------------------------------------------------
    // ���W�ϊ����s��
    // ---------------------------------------------------------------------------------------------------------------
    
    #if CV_ENABLE_2BONE_SKINNING
        // 2 �{�[���X�L�j���O�������s��
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
    // �[�x�����o�͂���
    //  -   �I�[�o�[���C���� z �� 0 �ɕύX���� (�[�x���͖�������)
    // ---------------------------------------------------------------------------------------------------------------
    
    #if CV_ENABLE_OVERLAY
        Output.Position.z   = 0.0f;
    #else
        Output.f4UV = Output.Position;  //< �ʏ�̃V���h�E�}�b�v���� UV �Ɏˉe��Ԃł̒��_���W���i�[���Ă���
    #endif

    // ---------------------------------------------------------------------------------------------------------------
    // �J���[�}�b�v�� UV ���o�͂���
    // ---------------------------------------------------------------------------------------------------------------
    
    #if CV_ENABLE_COLOR_MAP
        #if CV_USE_2ND_UV
            Output.f4UV.xy  = _Input.TexCoord1.xy;  //< ���e�e��UV1�Ńt�F�b�`���ׂ�
        #else
            Output.f4UV.xy  = _Input.TexCoord0.xy;
        #endif
    #endif
        
    return Output;
}