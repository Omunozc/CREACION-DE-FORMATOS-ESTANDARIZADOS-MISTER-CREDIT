USE [SBO_QATAR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[_SBOSP_FormatoImpreso_FEL_NC] (@DocKey@ Int, @ObjectId@ INT)
AS
BEGIN

    -- =====================================================================
    -- 1. DECLARACION DE TABLA EN MEMORIA PARA MOSTRAR LOS DATOS (COMPLETA)
    -- =====================================================================
    DECLARE @TABLA_LAYOUT TABLE (
        DocEntry            INT, 
        CardCode            NVARCHAR(15), 
        Address             NVARCHAR(254), 
        U_DoctoNo           NVARCHAR(25), 
        DocTotal            NUMERIC(19,2), 
        DocDate             VARCHAR(50), 
        Printed             CHAR(1),
        U_Nombre            NVARCHAR(150), 
        U_Grupo             NVARCHAR(20),
        U_Comercial         NVARCHAR(100), 
        U_Nit               NVARCHAR(15), 
        U_Direccion         NVARCHAR(200), 
        U_Telefonos         NVARCHAR(20), 
        U_Serie             NVARCHAR(30), 
        U_Del               INT, 
        U_Al                INT, 
        U_Fecha             DATETIME, 
        U_Resolucion        NVARCHAR(30), 
        Quantity            NVARCHAR(30), 
        ItemCode            NVARCHAR(30), 
        DiscPrcnt           NUMERIC(19,2), 
        PriceBefDi          NUMERIC(19,2), 
        USER_CODE           NVARCHAR(15), 
        PriceAfVAT          NUMERIC(19,2), 
        U_UNit              NVARCHAR(20), 
        LineTotal           NUMERIC(19,2), 
        DiscSum             NUMERIC(19,2), 
        Dscription          NVARCHAR(4000), 
        GroupNum            SMALLINT, 
        PymntGroup          NVARCHAR(100), 
        BankCode            NVARCHAR(30), 
        CheckNum            INT, 
        U_Fax               NVARCHAR(20), 
        U_Empresa           NVARCHAR(100), 
        U_FE_CAE            NVARCHAR(254), 
        NumAtCard           NVARCHAR(100), 
        DocCur              NVARCHAR(3), 
        DocTotalFC          NUMERIC(19,2), 
        PriceBefDiFC        NUMERIC(19,2), 
        TotalFrgn           NUMERIC(19,2), 
        VatSumFrgn          NUMERIC(19,2), 
        Descuento           NUMERIC(19,2), 
        vendedor            INT, 
        NombreVend          VARCHAR(100), 
        canceled            NVARCHAR(1), 
        DescuentoFrgn       NUMERIC(19,2), 
        DocRate             NUMERIC(19,6), 
        Comentarios         NVARCHAR(200), 
        MP_Cheque           NVARCHAR(30), 
        MP_Efectivo         NVARCHAR(30), 
        MP_NoDocto          NVARCHAR(30), 
        MP_BancoTC          NVARCHAR(30), 
        Enganche            NUMERIC(19,2), 
        NoCuotas            INT, 
        ValorCuotas         NUMERIC(19,2),
        adicional_1         NVARCHAR(100), 
        adicional_2         NVARCHAR(100), 
        adicional_3         NVARCHAR(100), 
        adicional_4         NVARCHAR(250), 
        adicional_5         NVARCHAR(100), 
        adicional_6         NVARCHAR(100), 
        adicional_7         NVARCHAR(100), 
        adicional_8         NVARCHAR(100), 
        adicional_9         NVARCHAR(100), 
        adicional_10        NVARCHAR(100), 
        adicional_11        NVARCHAR(100), 
        adicional_12        NVARCHAR(100), 
        adicional_13        NVARCHAR(100), 
        adicional_14        NVARCHAR(100), 
        Tipo_Identificacion NVARCHAR(100)
    )

    -- =====================================================================
    -- 2. VARIABLES Y PAGOS RECIBIDOS (Cambiado a '14' para Notas de Crédito)
    -- =====================================================================
    DECLARE @Fecha DateTime
    DECLARE @Cliente VarChar(50)
    
    DECLARE @PagosR TABLE (
        InvDocEntry INT, 
        InvType     VARCHAR(10), 
        [CheckSum]  MONEY, 
        CashSum     MONEY, 
        TrsfrSum    MONEY, 
        CreditSum   MONEY, 
        CheckNum    VARCHAR(50), 
        VoucherNum  VARCHAR(50), 
        BankCode    VARCHAR(50), 
        CreditCard  VARCHAR(50)
    )

    SELECT  
        @Fecha = T0.DocDate, 
        @Cliente = T0.CardCode 
    FROM ORIN (NOLOCK) T0
    WHERE T0.DocEntry = @DocKey@

    INSERT INTO @PagosR
    SELECT TOP 1 
        T1.InvDocEntry, 
        T1.InvType, 
        T1.[CheckSum], 
        T1.CashSum, 
        T1.TrsfrSum, 
        T1.CreditSum, 
        T1.CheckNum, 
        T1.VoucherNum, 
        T1.BankCode, 
        T1.CreditCard
    FROM ORIN (NOLOCK) T0 
    LEFT JOIN dbo._SBOF_PagosRecibidos(@Fecha, @Fecha, @Cliente, '14') T1 ON T0.DocEntry = T1.InvDocEntry AND T0.ObjType = T1.InvType
    WHERE T0.DocEntry = @DocKey@

    -- =====================================================================
    -- 3. BLOQUE FORMATO 01 (Detallado estándar con líneas de texto RIN10)
    -- =====================================================================
    IF (SELECT T1.U_formato_factura FROM ORIN T1 WITH (NOLOCK) WHERE T1.DocEntry = @DocKey@) = '01'
    BEGIN
        INSERT INTO @TABLA_LAYOUT 
        SELECT 
            T0.DocNum, 
            T2.CardCode, 
            T0.Address, 
            T0.U_DoctoNo, 
            T0.DocTotal, 
            CONVERT(VARCHAR, T0.DocDate, 103) AS DocDate, 
            T0.Printed,
            CASE WHEN T0.U_FE_Contingencia = 'Y' AND T0.U_FE_IDGFace IS NULL THEN T0.U_Nombre ELSE ISNULL(T0.U_Nombre, T0.U_Nombre) END AS U_Nombre, 
            ' ' AS U_Grupo, 
            T3.U_Comercial, 
            T3.U_Nit, 
            ISNULL(T3.U_Direccion, '') AS U_Direccion, 
            T3.U_Telefonos, 
            T0.U_DoctoSerie, 
            T3.U_Del, 
            T3.U_Al, 
            T3.U_Fecha, 
            T3.U_Resolucion,
            CASE WHEN T1.Quantity = 0 THEN '1' ELSE CONVERT(NVARCHAR(30), T1.Quantity) END AS Quantity,
            ISNULL(T1.ItemCode, 'Servicio') AS ItemCode, 
            T1.DiscPrcnt, 
            (T1.PriceBefDi * 1.12) AS PriceBefDi, 
            T5.USER_CODE, 
            T1.PriceAfVAT, 
            T0.U_Nit AS U_UNit, 
            CASE WHEN T0.DocType = 'S' THEN T0.DocTotal ELSE T1.LineTotal + T1.VatSum END AS LineTotal,
            T0.DiscSum, 
            CASE WHEN (SELECT ManSerNum FROM OITM WHERE ItemCode = T1.ItemCode) = 'Y' 
                 THEN SUBSTRING(T1.Dscription, 0, 2000) + (SELECT [dbo].[_SBOSP_FormatoImpreso_FEL_Obtener_Series_enDescrip](T0.DocEntry, T1.ItemCode)) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
                 ELSE SUBSTRING(T1.Dscription, 0, 2000) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
            END AS Dscription,
            T0.GroupNum, 
            T4.PymntGroup, 
            0 AS BankCode, 
            0 AS CheckNum, 
            T3.U_Fax, 
            T3.U_Empresa, 
            T0.U_FE_IDGFace, 
            T0.NumAtCard, 
            T0.DocCur, 
            T0.DocTotalFC, 
            ROUND((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END, 2) AS PriceBefDiFC,
            ROUND(((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END) * T1.Quantity, 2) AS TotalFrgn,
            T1.VatSumFrgn, 
            -ROUND(ROUND(ROUND((T1.PriceBefDi) * T1.Quantity, 2) * 1.12, 2) * T1.DiscPrcnt, 2) / 100 AS Descuento,
            T0.SlpCode, 
            T9.SlpName, 
            T0.CANCELED, 
            -ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2) AS DescuentoFrgn,
            T0.DocRate, 
            ' ' AS Comentarios,
            CASE WHEN (T8.[CheckSum] > 0 OR T8.CreditSum > 0) THEN 'X' ELSE '' END AS MP_Cheque,
            CASE WHEN (T8.CashSum > 0 OR T8.TrsfrSum > 0) THEN 'X' ELSE '' END AS MP_Efectivo,
            ISNULL('CH: ' + CONVERT(VARCHAR, T8.CheckNum) + ' - ', '') + ISNULL('VOU: ' + T8.VoucherNum, '') AS MP_NoDocto,
            ISNULL(T8.BankCode + ' - ', '') + ISNULL('TC: ' + T8.CreditCard, '') AS MP_BancoTC,
            0 AS Enganche, 
            0 AS NoCuotas, 
            0 AS ValorCuotas, 
            ISNULL(T10.TrnspName, 'N') AS adicional_1, 
            ISNULL(T0.CardName, '') AS adicional_2, 
            ISNULL(T0.CardCode, '') AS adicional_3, 
            ISNULL(T0.Address, '') AS adicional_4,
            CONVERT(VARCHAR, ISNULL(T0.U_DoctoSerieAdmin, '')) + CONVERT(VARCHAR, ISNULL(T0.U_DoctoNoAdmin, '')) AS adicional_5,
            T0.U_FE_Numero_Acceso AS adicional_6, 
            ISNULL(T0.U_FE_Contingencia, 'N') AS adicional_7, 
            T0.U_FE_Status AS adicional_8, 
            T0.U_DoctoSerieAdmin AS adicional_9, 
            T0.U_DoctoNoAdmin AS adicional_10, 
            (SELECT GroupCode FROM OCRD WHERE CardCode = T0.CardCode) AS adicional_11, 
            '' AS adicional_12, 
            '' AS adicional_13, 
            CASE WHEN T0.DocDate >= '20200710' THEN 'Y' ELSE 'N' END AS adicional_14, 
            ISNULL(T0.U_FE_Tipo_Identificacion, '') AS Tipo_Identificacion
        FROM ORIN T0 WITH (NOLOCK)
        INNER JOIN RIN1 T1 WITH (NOLOCK) ON T0.DocEntry = T1.DocEntry
        LEFT JOIN RIN10 T100 WITH (NOLOCK) ON T1.DocEntry = T100.DocEntry AND T1.LineNum = T100.AftLineNum
        INNER JOIN OCRD T2 WITH (NOLOCK) ON T0.CardCode = T2.CardCode
        LEFT JOIN [@RESOLUCIONES] T3 ON T3.U_Resolucion = T0.U_FE_Res
        INNER JOIN OCTG T4 WITH (NOLOCK) ON T0.GroupNum = T4.GroupNum
        INNER JOIN OUSR T5 WITH (NOLOCK) ON T0.UserSign = T5.INTERNAL_K
        LEFT JOIN @PagosR T8 ON T0.DocEntry = T8.InvDocEntry AND T8.InvType = T0.ObjType
        LEFT JOIN OSLP T9 ON T0.SlpCode = T9.SlpCode
        LEFT JOIN OSHP T10 ON T10.TrnspCode = T0.TrnspCode
        WHERE T0.DocEntry = @DocKey@ AND T0.ObjType = @ObjectId@
    END

    -- =====================================================================
    -- 4. BLOQUE FORMATO 02 (Agrupado, sin líneas de texto)
    -- =====================================================================
    IF (SELECT T1.U_formato_factura FROM ORIN T1 WITH (NOLOCK) WHERE T1.DocEntry = @DocKey@) = '02'
    BEGIN
        INSERT INTO @TABLA_LAYOUT 
        SELECT 
            T0.DocNum, 
            T2.CardCode, 
            T0.Address, 
            T0.U_DoctoNo, 
            T0.DocTotal, 
            CONVERT(VARCHAR, T0.DocDate, 103) AS DocDate, 
            T0.Printed,
            CASE WHEN T0.U_FE_Contingencia = 'Y' AND T0.U_FE_IDGFace IS NULL THEN T0.U_Nombre ELSE ISNULL(T0.U_Nombre, T0.U_Nombre) END AS U_Nombre, 
            ' ' AS U_Grupo, 
            T3.U_Comercial, 
            T3.U_Nit, 
            ISNULL(T3.U_Direccion, '') AS U_Direccion, 
            T3.U_Telefonos, 
            T3.U_Serie, 
            T3.U_Del, 
            T3.U_Al, 
            T3.U_Fecha, 
            T3.U_Resolucion,
            SUM(CASE WHEN T1.Quantity = 0 THEN 1 ELSE T1.Quantity END) AS Quantity,
            '' AS ItemCode, 
            0 AS DiscPrcnt, 
            0 AS PriceBefDi, 
            T5.USER_CODE, 
            0 AS PriceAfVAT, 
            T0.U_Nit AS U_UNit, 
            SUM(T1.LineTotal + T1.VatSum) AS LineTotal, 
            T0.DiscSum, 
            T1.Dscription, 
            T0.GroupNum, 
            T4.PymntGroup, 
            0 AS BankCode, 
            0 AS CheckNum, 
            T3.U_Fax, 
            T3.U_Empresa, 
            T0.U_FE_IDGFace, 
            T0.NumAtCard, 
            T0.DocCur, 
            T0.DocTotalFC, 
            SUM(ROUND((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END, 2)) AS PriceBefDiFC,
            SUM(ROUND(((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END) * T1.Quantity, 2)) AS TotalFrgn,
            SUM(T1.VatSumFrgn) AS VatSumFrgn, 
            SUM(-ROUND(ROUND(ROUND((T1.PriceBefDi) * T1.Quantity, 2) * 1.12, 2) * T1.DiscPrcnt, 2) / 100) AS Descuento,
            T0.SlpCode, 
            T9.SlpName, 
            T0.CANCELED, 
            SUM(-ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) AS DescuentoFrgn,
            T0.DocRate, 
            ' ' AS Comentarios, 
            CASE WHEN (T8.[CheckSum] > 0 OR T8.CreditSum > 0) THEN 'X' ELSE '' END AS MP_Cheque, 
            CASE WHEN (T8.CashSum > 0 OR T8.TrsfrSum > 0) THEN 'X' ELSE '' END AS MP_Efectivo,
            ISNULL('CH: ' + CONVERT(VARCHAR, T8.CheckNum) + ' - ', '') + ISNULL('VOU: ' + T8.VoucherNum, '') AS MP_NoDocto, 
            ISNULL(T8.BankCode + ' - ', '') + ISNULL('TC: ' + T8.CreditCard, '') AS MP_BancoTC,
            0 AS Enganche, 
            0 AS NoCuotas, 
            0 AS ValorCuotas, 
            ISNULL(T10.TrnspName, 'N') AS adicional_1, 
            ISNULL(T0.CardName, '') AS adicional_2, 
            ISNULL(T0.CardCode, '') AS adicional_3, 
            ISNULL(T0.Address, '') AS adicional_4,
            CONVERT(VARCHAR, ISNULL(T0.U_DoctoSerieAdmin, '')) + CONVERT(VARCHAR, ISNULL(T0.U_DoctoNoAdmin, '')) AS adicional_5, 
            T0.U_FE_Numero_Acceso AS adicional_6, 
            ISNULL(T0.U_FE_Contingencia, 'N') AS adicional_7, 
            T0.U_FE_Status AS adicional_8, 
            T0.U_DoctoSerieAdmin AS adicional_9, 
            T0.U_DoctoNoAdmin AS adicional_10, 
            (SELECT GroupCode FROM OCRD WHERE CardCode = T0.CardCode) AS adicional_11, 
            '' AS adicional_12, 
            '' AS adicional_13, 
            CASE WHEN T0.DocDate >= '20200710' THEN 'Y' ELSE 'N' END AS adicional_14, 
            ISNULL(T0.U_FE_Tipo_Identificacion, '') AS Tipo_Identificacion
        FROM ORIN T0 WITH (NOLOCK)
        INNER JOIN RIN1 T1 WITH (NOLOCK) ON T0.DocEntry = T1.DocEntry
        INNER JOIN OCRD T2 WITH (NOLOCK) ON T0.CardCode = T2.CardCode
        LEFT JOIN [@RESOLUCIONES] T3 ON T3.U_Resolucion = T0.U_FE_Res
        INNER JOIN OCTG T4 WITH (NOLOCK) ON T0.GroupNum = T4.GroupNum
        INNER JOIN OUSR T5 WITH (NOLOCK) ON T0.UserSign = T5.INTERNAL_K
        LEFT JOIN @PagosR T8 ON T0.DocEntry = T8.InvDocEntry AND T8.InvType = T0.ObjType
        LEFT JOIN OSLP T9 ON T0.SlpCode = T9.SlpCode
        LEFT JOIN OSHP T10 ON T10.TrnspCode = T0.TrnspCode
        WHERE T0.DocEntry = @DocKey@ AND T0.ObjType = @ObjectId@
        GROUP BY 
            T0.DocNum, 
            T2.CardCode, 
			T0.CardCode,      
            T0.Address, 
            T0.U_DoctoNo, 
            T0.DocTotal, 
            T0.DocDate, 
            T0.Printed, 
            T0.U_FE_Contingencia, 
            T0.U_FE_IDGFace, 
            T0.U_Nombre, 
            T3.U_Comercial, 
            T3.U_Nit, 
            T3.U_Direccion, 
            T3.U_Telefonos, 
            T3.U_Serie, 
            T3.U_Del, 
            T3.U_Al, 
            T3.U_Fecha, 
            T3.U_Resolucion, 
            T5.USER_CODE,
            T0.U_Nit, 
            T0.DiscSum, 
            T1.Dscription, 
            T0.GroupNum, 
            T4.PymntGroup, 
            T3.U_Fax, 
            T3.U_Empresa, 
            T0.NumAtCard, 
            T0.DocCur, 
            T0.DocTotalFC, 
            T0.SlpCode, 
            T9.SlpName, 
            T0.CANCELED, 
            T0.DocRate, 
            T8.[CheckSum], 
            T8.CreditSum, 
            T8.CashSum, 
            T8.TrsfrSum, 
            T8.CheckNum, 
            T8.VoucherNum, 
            T8.BankCode,
            T8.CreditCard, 
            T10.TrnspName, 
            T0.CardName, 
            T0.U_DoctoSerieAdmin, 
            T0.U_DoctoNoAdmin, 
            T0.U_FE_Numero_Acceso, 
            T0.U_FE_Status, 
            T0.U_FE_Tipo_Identificacion
    END

    -- =====================================================================
    -- 5. BLOQUE FORMATO 03 (Variante detallada)
    -- =====================================================================
    IF (SELECT T1.U_formato_factura FROM ORIN T1 WITH (NOLOCK) WHERE T1.DocEntry = @DocKey@) = '03'
    BEGIN
        INSERT INTO @TABLA_LAYOUT 
        SELECT 
            T0.DocNum, 
            T2.CardCode, 
            T0.Address, 
            T0.U_DoctoNo, 
            T0.DocTotal, 
            CONVERT(VARCHAR, T0.DocDate, 103) AS DocDate, 
            T0.Printed,
            CASE WHEN T0.U_FE_Contingencia = 'Y' AND T0.U_FE_IDGFace IS NULL THEN T0.U_Nombre ELSE ISNULL(T0.U_Nombre, T0.U_Nombre) END AS U_Nombre, 
            ' ' AS U_Grupo, 
            T3.U_Comercial, 
            T3.U_Nit, 
            ISNULL(T3.U_Direccion, '') AS U_Direccion, 
            T3.U_Telefonos, 
            T0.U_DoctoSerie, 
            T3.U_Del, 
            T3.U_Al, 
            T3.U_Fecha, 
            T3.U_Resolucion,
            CASE WHEN T1.Quantity = 0 THEN '1' ELSE CONVERT(NVARCHAR(30), T1.Quantity) END AS Quantity,
            ISNULL(T1.ItemCode, 'Servicio') AS ItemCode, 
            T1.DiscPrcnt, 
            (T1.PriceBefDi * 1.12) AS PriceBefDi, 
            T5.USER_CODE, 
            T1.PriceAfVAT, 
            T0.U_Nit AS U_UNit, 
            CASE WHEN T0.DocType = 'S' THEN T0.DocTotal ELSE T1.LineTotal + T1.VatSum END AS LineTotal, 
            T0.DiscSum, 
            CASE WHEN (SELECT ManSerNum FROM OITM WHERE ItemCode = T1.ItemCode) = 'Y' 
                 THEN SUBSTRING(T1.Dscription, 0, 2000) + (SELECT [dbo].[_SBOSP_FormatoImpreso_FEL_Obtener_Series_enDescrip](T0.DocEntry, T1.ItemCode)) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
                 ELSE SUBSTRING(T1.Dscription, 0, 2000) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
            END AS Dscription,
            T0.GroupNum, 
            T4.PymntGroup, 
            0 AS BankCode, 
            0 AS CheckNum, 
            T3.U_Fax, 
            T3.U_Empresa, 
            T0.U_FE_IDGFace, 
            T0.NumAtCard, 
            T0.DocCur, 
            T0.DocTotalFC, 
            ROUND((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END, 2) AS PriceBefDiFC,
            ROUND(((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END) * T1.Quantity, 2) AS TotalFrgn,
            T1.VatSumFrgn, 
            -ROUND(ROUND(ROUND((T1.PriceBefDi) * T1.Quantity, 2) * 1.12, 2) * T1.DiscPrcnt, 2) / 100 AS Descuento,
            T0.SlpCode, 
            T9.SlpName, 
            T0.CANCELED, 
            -ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2) AS DescuentoFrgn,
            T0.DocRate, 
            ' ' AS Comentarios, 
            CASE WHEN (T8.[CheckSum] > 0 OR T8.CreditSum > 0) THEN 'X' ELSE '' END AS MP_Cheque, 
            CASE WHEN (T8.CashSum > 0 OR T8.TrsfrSum > 0) THEN 'X' ELSE '' END AS MP_Efectivo,
            ISNULL('CH: ' + CONVERT(VARCHAR, T8.CheckNum) + ' - ', '') + ISNULL('VOU: ' + T8.VoucherNum, '') AS MP_NoDocto, 
            ISNULL(T8.BankCode + ' - ', '') + ISNULL('TC: ' + T8.CreditCard, '') AS MP_BancoTC,
            0 AS Enganche, 
            0 AS NoCuotas, 
            0 AS ValorCuotas, 
            ISNULL(T10.TrnspName, 'N') AS adicional_1, 
            ISNULL(T0.CardName, '') AS adicional_2, 
            ISNULL(T0.CardCode, '') AS adicional_3, 
            ISNULL(T0.Address, '') AS adicional_4,
            CONVERT(VARCHAR, ISNULL(T0.U_DoctoSerieAdmin, '')) + CONVERT(VARCHAR, ISNULL(T0.U_DoctoNoAdmin, '')) AS adicional_5, 
            T0.U_FE_Numero_Acceso AS adicional_6, 
            ISNULL(T0.U_FE_Contingencia, 'N') AS adicional_7, 
            T0.U_FE_Status AS adicional_8, 
            T0.U_DoctoSerieAdmin AS adicional_9, 
            T0.U_DoctoNoAdmin AS adicional_10, 
            (SELECT GroupCode FROM OCRD WHERE CardCode = T0.CardCode) AS adicional_11, 
            '' AS adicional_12, 
            '' AS adicional_13, 
            CASE WHEN T0.DocDate >= '20200710' THEN 'Y' ELSE 'N' END AS adicional_14, 
            ISNULL(T0.U_FE_Tipo_Identificacion, '') AS Tipo_Identificacion
        FROM ORIN T0 WITH (NOLOCK)
        INNER JOIN RIN1 T1 WITH (NOLOCK) ON T0.DocEntry = T1.DocEntry
        LEFT JOIN RIN10 T100 WITH (NOLOCK) ON T1.DocEntry = T100.DocEntry AND T1.LineNum = T100.AftLineNum
        INNER JOIN OCRD T2 WITH (NOLOCK) ON T0.CardCode = T2.CardCode
        LEFT JOIN [@RESOLUCIONES] T3 ON T3.U_Resolucion = T0.U_FE_Res
        INNER JOIN OCTG T4 WITH (NOLOCK) ON T0.GroupNum = T4.GroupNum
        INNER JOIN OUSR T5 WITH (NOLOCK) ON T0.UserSign = T5.INTERNAL_K
        LEFT JOIN @PagosR T8 ON T0.DocEntry = T8.InvDocEntry AND T8.InvType = T0.ObjType
        LEFT JOIN OSLP T9 ON T0.SlpCode = T9.SlpCode
        LEFT JOIN OSHP T10 ON T10.TrnspCode = T0.TrnspCode
        WHERE T0.DocEntry = @DocKey@ AND T0.ObjType = @ObjectId@
    END

    -- =====================================================================
    -- 6. BLOQUE FORMATO 04 
    -- =====================================================================
    IF (SELECT T1.U_formato_factura FROM ORIN T1 WITH (NOLOCK) WHERE T1.DocEntry = @DocKey@) = '04'
    BEGIN
        INSERT INTO @TABLA_LAYOUT 
        SELECT 
            T0.DocNum, 
            T2.CardCode, 
            T0.Address, 
            T0.U_DoctoNo, 
            T0.DocTotal, 
            CONVERT(VARCHAR, T0.DocDate, 103) AS DocDate, 
            T0.Printed,
            CASE WHEN T0.U_FE_Contingencia = 'Y' AND T0.U_FE_IDGFace IS NULL THEN T0.U_Nombre ELSE ISNULL(T0.U_Nombre, T0.U_Nombre) END AS U_Nombre, 
            ' ' AS U_Grupo, 
            T3.U_Comercial, 
            T3.U_Nit, 
            ISNULL(T3.U_Direccion, '') AS U_Direccion, 
            T3.U_Telefonos, 
            T0.U_DoctoSerie, 
            T3.U_Del, 
            T3.U_Al, 
            T3.U_Fecha, 
            T3.U_Resolucion,
            CASE WHEN T1.Quantity = 0 THEN '1' ELSE CONVERT(NVARCHAR(30), T1.Quantity) END AS Quantity,
            ISNULL(T1.ItemCode, 'Servicio') AS ItemCode, 
            T1.DiscPrcnt, 
            (T1.PriceBefDi * 1.12) AS PriceBefDi, 
            T5.USER_CODE, 
            T1.PriceAfVAT, 
            T0.U_Nit AS U_UNit, 
            CASE WHEN T0.DocType = 'S' THEN T0.DocTotal ELSE T1.LineTotal + T1.VatSum END AS LineTotal, 
            T0.DiscSum, 
            CASE WHEN (SELECT ManSerNum FROM OITM WHERE ItemCode = T1.ItemCode) = 'Y' 
                 THEN SUBSTRING(T1.Dscription, 0, 2000) + (SELECT [dbo].[_SBOSP_FormatoImpreso_FEL_Obtener_Series_enDescrip](T0.DocEntry, T1.ItemCode)) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
                 ELSE SUBSTRING(T1.Dscription, 0, 2000) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
            END AS Dscription,
            T0.GroupNum, 
            T4.PymntGroup, 
            0 AS BankCode, 
            0 AS CheckNum, 
            T3.U_Fax, 
            T3.U_Empresa, 
            T0.U_FE_IDGFace, 
            T0.NumAtCard, 
            T0.DocCur, 
            T0.DocTotalFC, 
            ROUND((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END, 2) AS PriceBefDiFC,
            ROUND(((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END) * T1.Quantity, 2) AS TotalFrgn,
            T1.VatSumFrgn, 
            -ROUND(ROUND(ROUND((T1.PriceBefDi) * T1.Quantity, 2) * 1.12, 2) * T1.DiscPrcnt, 2) / 100 AS Descuento,
            T0.SlpCode, 
            T9.SlpName, 
            T0.CANCELED, 
            -ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2) AS DescuentoFrgn,
            T0.DocRate, 
            ' ' AS Comentarios, 
            CASE WHEN (T8.[CheckSum] > 0 OR T8.CreditSum > 0) THEN 'X' ELSE '' END AS MP_Cheque, 
            CASE WHEN (T8.CashSum > 0 OR T8.TrsfrSum > 0) THEN 'X' ELSE '' END AS MP_Efectivo,
            ISNULL('CH: ' + CONVERT(VARCHAR, T8.CheckNum) + ' - ', '') + ISNULL('VOU: ' + T8.VoucherNum, '') AS MP_NoDocto, 
            ISNULL(T8.BankCode + ' - ', '') + ISNULL('TC: ' + T8.CreditCard, '') AS MP_BancoTC,
            0 AS Enganche, 
            0 AS NoCuotas, 
            0 AS ValorCuotas, 
            ISNULL(T10.TrnspName, 'N') AS adicional_1, 
            ISNULL(T0.CardName, '') AS adicional_2, 
            ISNULL(T0.CardCode, '') AS adicional_3, 
            ISNULL(T0.Address, '') AS adicional_4,
            CONVERT(VARCHAR, ISNULL(T0.U_DoctoSerieAdmin, '')) + CONVERT(VARCHAR, ISNULL(T0.U_DoctoNoAdmin, '')) AS adicional_5, 
            T0.U_FE_Numero_Acceso AS adicional_6, 
            ISNULL(T0.U_FE_Contingencia, 'N') AS adicional_7, 
            T0.U_FE_Status AS adicional_8, 
            T0.U_DoctoSerieAdmin AS adicional_9, 
            T0.U_DoctoNoAdmin AS adicional_10, 
            (SELECT GroupCode FROM OCRD WHERE CardCode = T0.CardCode) AS adicional_11, 
            '' AS adicional_12, 
            '' AS adicional_13, 
            CASE WHEN T0.DocDate >= '20200710' THEN 'Y' ELSE 'N' END AS adicional_14, 
            ISNULL(T0.U_FE_Tipo_Identificacion, '') AS Tipo_Identificacion
        FROM ORIN T0 WITH (NOLOCK)
        INNER JOIN RIN1 T1 WITH (NOLOCK) ON T0.DocEntry = T1.DocEntry
        LEFT JOIN RIN10 T100 WITH (NOLOCK) ON T1.DocEntry = T100.DocEntry AND T1.LineNum = T100.AftLineNum
        INNER JOIN OCRD T2 WITH (NOLOCK) ON T0.CardCode = T2.CardCode
        LEFT JOIN [@RESOLUCIONES] T3 ON T3.U_Resolucion = T0.U_FE_Res
        INNER JOIN OCTG T4 WITH (NOLOCK) ON T0.GroupNum = T4.GroupNum
        INNER JOIN OUSR T5 WITH (NOLOCK) ON T0.UserSign = T5.INTERNAL_K
        LEFT JOIN @PagosR T8 ON T0.DocEntry = T8.InvDocEntry AND T8.InvType = T0.ObjType
        LEFT JOIN OSLP T9 ON T0.SlpCode = T9.SlpCode
        LEFT JOIN OSHP T10 ON T10.TrnspCode = T0.TrnspCode
        WHERE T0.DocEntry = @DocKey@ AND T0.ObjType = @ObjectId@
    END

    -- =====================================================================
    -- 7. BLOQUE FORMATO 05 (Exportación - Dólares)
    -- =====================================================================
    IF (SELECT T1.U_formato_factura FROM ORIN T1 WITH (NOLOCK) WHERE T1.DocEntry = @DocKey@) = '05'
    BEGIN
        INSERT INTO @TABLA_LAYOUT 
        SELECT 
            T0.DocNum, 
            T2.CardCode, 
            T0.Address, 
            T0.U_DoctoNo, 
            T0.DocTotal, 
            CONVERT(VARCHAR, T0.DocDate, 103) AS DocDate, 
            T0.Printed,
            CASE WHEN T0.U_FE_Contingencia = 'Y' AND T0.U_FE_IDGFace IS NULL THEN T0.U_Nombre ELSE ISNULL(T0.U_Nombre, T0.U_Nombre) END AS U_Nombre, 
            ' ' AS U_Grupo, 
            T3.U_Comercial, 
            T3.U_Nit, 
            ISNULL(T3.U_Direccion, '') AS U_Direccion, 
            T3.U_Telefonos, 
            T0.U_DoctoSerie, 
            T3.U_Del, 
            T3.U_Al, 
            T3.U_Fecha, 
            T3.U_Resolucion,
            CASE WHEN T1.Quantity = 0 THEN '1' ELSE CONVERT(NVARCHAR(30), T1.Quantity) END AS Quantity,
            ISNULL(T1.ItemCode, 'Servicio') AS ItemCode, 
            T1.DiscPrcnt, 
            (T1.PriceBefDi * 1.12) AS PriceBefDi, 
            T5.USER_CODE, 
            T1.PriceAfVAT, 
            T0.U_Nit AS U_UNit, 
            CASE WHEN T0.DocType = 'S' THEN T0.DocTotal ELSE T1.LineTotal + T1.VatSum END AS LineTotal, 
            T0.DiscSum, 
            CASE WHEN (SELECT ManSerNum FROM OITM WHERE ItemCode = T1.ItemCode) = 'Y' 
                 THEN SUBSTRING(T1.Dscription, 0, 2000) + (SELECT [dbo].[_SBOSP_FormatoImpreso_FEL_Obtener_Series_enDescrip](T0.DocEntry, T1.ItemCode)) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
                 ELSE SUBSTRING(T1.Dscription, 0, 2000) + ISNULL(SUBSTRING(T1.U_articulo_des, 0, 2000), '') + ISNULL(' ' + CAST(T100.LineText AS NVARCHAR(MAX)), '')
            END AS Dscription,
            T0.GroupNum, 
            T4.PymntGroup, 
            0 AS BankCode, 
            0 AS CheckNum, 
            T3.U_Fax, 
            T3.U_Empresa, 
            T0.U_FE_IDGFace, 
            T0.NumAtCard, 
            T0.DocCur, 
            T0.DocTotalFC, 
            ROUND((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END, 2) AS PriceBefDiFC,
            ROUND(((ROUND(T1.TotalFrgn + T1.VatSumFrgn, 2) + ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2)) / CASE WHEN T1.QUANTITY = 0 THEN 1 ELSE T1.QUANTITY END) * T1.Quantity, 2) AS TotalFrgn,
            T1.VatSumFrgn, 
            -ROUND(ROUND(ROUND((T1.PriceBefDi) * T1.Quantity, 2) * 1.12, 2) * T1.DiscPrcnt, 2) / 100 AS Descuento,
            T0.SlpCode, 
            T9.SlpName, 
            T0.CANCELED, 
            -ROUND((ISNULL(T1.QUANTITY, 1) * ROUND(((T1.PriceBefDi / T0.DocRate) - (T1.INMPrice / T0.DocRate)), 2) * 1.12), 2) AS DescuentoFrgn,
            T0.DocRate, 
            ' ' AS Comentarios, 
            CASE WHEN (T8.[CheckSum] > 0 OR T8.CreditSum > 0) THEN 'X' ELSE '' END AS MP_Cheque, 
            CASE WHEN (T8.CashSum > 0 OR T8.TrsfrSum > 0) THEN 'X' ELSE '' END AS MP_Efectivo,
            ISNULL('CH: ' + CONVERT(VARCHAR, T8.CheckNum) + ' - ', '') + ISNULL('VOU: ' + T8.VoucherNum, '') AS MP_NoDocto, 
            ISNULL(T8.BankCode + ' - ', '') + ISNULL('TC: ' + T8.CreditCard, '') AS MP_BancoTC,
            0 AS Enganche, 
            0 AS NoCuotas, 
            0 AS ValorCuotas, 
            ISNULL(T10.TrnspName, 'N') AS adicional_1, 
            ISNULL(T0.CardName, '') AS adicional_2, 
            ISNULL(T0.CardCode, '') AS adicional_3, 
            ISNULL(T0.Address, '') AS adicional_4,
            CONVERT(VARCHAR, ISNULL(T0.U_DoctoSerieAdmin, '')) + CONVERT(VARCHAR, ISNULL(T0.U_DoctoNoAdmin, '')) AS adicional_5, 
            T0.U_FE_Numero_Acceso AS adicional_6, 
            ISNULL(T0.U_FE_Contingencia, 'N') AS adicional_7, 
            T0.U_FE_Status AS adicional_8, 
            T0.U_DoctoSerieAdmin AS adicional_9, 
            T0.U_DoctoNoAdmin AS adicional_10, 
            (SELECT GroupCode FROM OCRD WHERE CardCode = T0.CardCode) AS adicional_11, 
            '' AS adicional_12, 
            '' AS adicional_13, 
            CASE WHEN T0.DocDate >= '20200710' THEN 'Y' ELSE 'N' END AS adicional_14, 
            ISNULL(T0.U_FE_Tipo_Identificacion, '') AS Tipo_Identificacion
        FROM ORIN T0 WITH (NOLOCK)
        INNER JOIN RIN1 T1 WITH (NOLOCK) ON T0.DocEntry = T1.DocEntry
        LEFT JOIN RIN10 T100 WITH (NOLOCK) ON T1.DocEntry = T100.DocEntry AND T1.LineNum = T100.AftLineNum
        INNER JOIN OCRD T2 WITH (NOLOCK) ON T0.CardCode = T2.CardCode
        LEFT JOIN [@RESOLUCIONES] T3 ON T3.U_Resolucion = T0.U_FE_Res
        INNER JOIN OCTG T4 WITH (NOLOCK) ON T0.GroupNum = T4.GroupNum
        INNER JOIN OUSR T5 WITH (NOLOCK) ON T0.UserSign = T5.INTERNAL_K
        LEFT JOIN @PagosR T8 ON T0.DocEntry = T8.InvDocEntry AND T8.InvType = T0.ObjType
        LEFT JOIN OSLP T9 ON T0.SlpCode = T9.SlpCode
        LEFT JOIN OSHP T10 ON T10.TrnspCode = T0.TrnspCode
        WHERE T0.DocEntry = @DocKey@ AND T0.ObjType = @ObjectId@
    END

    -- =====================================================================
    -- 8. RESULTADO FINAL (El que lee el Crystal Reports)
    -- =====================================================================
    SELECT * FROM @TABLA_LAYOUT

END