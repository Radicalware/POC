
import QtQuick
pragma Singleton

QtObject
{
    property  int mWidth:  450
    property  int mHeight: 750

    readonly  property int mFontPixelSize: mWidth / 35
    readonly  property int mTextHeight: mFontPixelSize + (mFontPixelSize * 0.65)
    readonly  property string mTextColor: "#c7ddff"
}
