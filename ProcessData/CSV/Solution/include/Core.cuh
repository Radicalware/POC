#pragma once

#include "Macros.h"

struct ColumnData
{
    xint   Count = 0;
    double Mean = 0;
    double SD = 0;
    double SumDeviation = 0;
    double Variance = 0;
    double Min = 0;
    double Max = 0;
    double Sum = 0;
};
std::ostream& operator<<(std::ostream& out, const ColumnData& FoData);


class Core
{
public:
    Core(const xstring& FsFilePath);
    inline void SetFilePath(const xstring& FsPath) { MsFilePath = FsPath; }
    void  ReadData();
    void  ConfigureColumnValues();
    void  ParseResultColumnIdx(const xint Col);
    void  ParseResultsWtihCPU();
    void  ParseThreadedResultsWtihCPU(const bool FbForceRestart = false);
    auto& GetDataset(const xint FnValue) const { return MvResultData[FnValue]; }
private:
    xstring MsFilePath;
    xint    MnColumnCount = 0;
    xvector<xint> MvRange;
    xvector<xvector<xstring>> MvColumnValuesStr;
    xvector<xvector<double>>  MvColumnValues;
    xvector<double> MvBlankRow;
    bool MbParsed = false;
    xvector<ColumnData> MvResultData;
};