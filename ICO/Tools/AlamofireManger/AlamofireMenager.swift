//
//  AlamofireMenager.swift
//  RequestMenager
//
//  Created by 李鹏跃 on 2017/12/22.
//  Copyright © 2017年 13lipengyue. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import SVProgressHUD


///网络请求工具 对alamofire的封装
///根据success回调传入的<T>的类型返回对应的值
///T 为 [BaseMappable]，则返回数组，
///T 为BaseMappable，则返回对象，
///T 为Any，则返回Json字符串。
class AlamofireMenager: NSObject {
    static let shared = AlamofireMenager()
    ///code码处理 类
    var codeMenager: RespnseCodeMenager.Type = k_codeMenager
    
    ///请求错误的时候提示信息
    var errorShowMassage: String = "请求网络失败"
    let noNetString = "您处在离线状态"
    //是否展示无网视图
    var isShowNoWorking: Bool = true
    //是否有加载菊花提示视图
    var isShowLoading: Bool  = true
    
    private var requestDictionary = [String:String]()
    
    lazy var ykNoNetv = YKNoNetView()
    
    private func hideView(){
        guard let vc =  getCurrentVC()  else {
            return
        }
        if vc.view.subviews.count > 0 {
            let array: [UIView] = vc.view.subviews
            for v in (array) {
                if v.classForCoder == YKNoNetView.classForCoder(){
                    v.removeFromSuperview()
                }
            }
        }
//        guard let array: [UIView] = vc.view.subviews else {
//            return
//        }
        
//        for v in (array) {
//            if v.classForCoder == YKNoNetView.classForCoder(){
//                v.removeFromSuperview()
//            }
//        }
    }
    private func showView(){
        if self.isShowNoWorking {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.8) {
                let vc =  getCurrentVC()
                
                let y = (vc?.navigationController?.navigationBar.isHidden) ?? true ? 0.0 : navStatusHeight()
                let h = (vc?.tabBarController?.tabBar.isHidden) ?? true  ? ScreenHeight - y  : ScreenHeight - y - tabBarHeight()
                let f = CGRect(x: 0, y: y, width: ScreenWidth, height: h)
                self.ykNoNetv.frame = f
             
                vc?.view.addSubview(self.ykNoNetv)
            }
            
        }
    }
    
//    private func cancelRequest(path:String){
//        let request  = self.requestDictionary[path]
//        request?.cancel()
//    self.requestDictionary.removeValue(forKey: path)
//
//    }
    
    
    //MARK: - 下载数据 相关接口
    
    /// alamofire 数据请求 （数据为object）
    ///注意循环引用
    /// - Parameters:
    ///   - path: url path
    ///   - method: 请求方式
    ///   - parameters: 参数
    ///   - parametersType: 参数为 query 还是 body
    ///   - responseDateType: 网络数据类型
    ///   - success: 成功的回调
    ///   - failure: 失败的回调
    /// - Returns: Request
    @discardableResult
    func loadData<T:BaseMappable>(Path path: String, HTTPMethod method: HTTPMethod? = .get,_ parameters: [String:Any]? = nil,_ parametersType: ParamaetersType? = nil,_ setRequest: ((_ request: DataRequest) -> Void)? = nil,Success success: @escaping (_ M:T,_ response:DataResponse<T>) -> Void, Failure failure:@escaping(_ errorMsg:String) -> Void) -> (DataRequest?) {
    
        hideView()
        if YKNetworkStatus.sharedInstance.isConnect == false {
            showView()
         print(noNetString)
            return nil
        }
        //是否存在，存在 return 不存在请求
        //存入id
         let da = DataMD5.share()
        let id = da?.createMd5Id(parameters) ?? ""
        if self.requestDictionary[id] != nil {
            return nil
        }
           self.requestDictionary[id] = id
     
        
        guard let dataRequest = self.loadDataObject(Path: path,Id:id, HTTPMethod: method, parameters, parametersType, setRequest, Success: success, Failure: failure) else {
            return nil
        }
       
//        cancelRequest(path: path)
     //        self.requestDictionary[path] = dataTask
   
        return dataRequest
    }
    
    /// alamofire 数据请求 (数据Json)
    ///注意循环引用
    /// - Parameters:
    ///   - path: url path
    ///   - method: 请求方式
    ///   - parameters: 参数
    ///   - parametersType: 参数为 query 还是 body
    ///   - responseDateType: 网络数据类型
    ///   - success: 成功的回调
    ///   - failure: 失败的回调
    /// - Returns: Request
    @discardableResult
    func loadData(Path path: String, HTTPMethod method: HTTPMethod? = .get,_ parameters: [String:Any]? = nil,_ parametersType: ParamaetersType? = nil,_ setRequest: ((_ request: DataRequest) -> Void)? = nil,Success success: @escaping (_ json: Any,_ response: DataResponse<Any>) -> Void, Failure failure:@escaping(_ errorMsg:String) -> Void) -> (DataRequest?) {
        hideView()
        if YKNetworkStatus.sharedInstance.isConnect == false {
            showView()
            print(noNetString)
            return nil
        }
        let da = DataMD5.share()
        let id = da?.createMd5Id(parameters) ?? ""
        if self.requestDictionary[id] != nil {
            return nil
        }
      self.requestDictionary[id] = id
        
        guard let dataRequest = self.loadDataJson(Path: path,Id:id, HTTPMethod: method, parameters, parametersType, setRequest, Success: success, Failure: failure) else {
            return nil
        }
   
//        cancelRequest(path: path)
//        self.requestDictionary[path] = dataTask
        
        return dataRequest
       
    }
    
    /// alamofire 数据请求 (数据数组)
    ///注意循环引用
    /// - Parameters:
    ///   - path: url path
    ///   - method: 请求方式
    ///   - pxarameters: 参数
    ///   - parametersType: 参数为 query 还是 body
    ///   - responseDateType: 网络数据类型
    ///   - success: 成功的回调
    ///   - failure: 失败的回调
    /// - Returns: Request
    @discardableResult
    func loadData<T:BaseMappable>(Path path: String, HTTPMethod method: HTTPMethod? = .get,_ parameters: [String:Any]? = nil,_ parametersType: ParamaetersType? = nil,_ setRequest: ((_ request: DataRequest) -> Void)? = nil,Success success: @escaping ([T],_ response: DataResponse<[T]>) -> Void, Failure failure:@escaping(_ errorMsg:String) -> Void) -> (DataRequest?) {
        hideView()
        if YKNetworkStatus.sharedInstance.isConnect == false {
            showView()
            print(noNetString)
            return nil
        }
        //是否存在，存在 return 不存在请求
        //存入id
        let da = DataMD5.share()
        let id = da?.createMd5Id(parameters) ?? ""
        if self.requestDictionary[id] != nil {
            return nil
        }
        self.requestDictionary[id] = id
        guard let dataTask = self.loadDataArray(Path: path,Id:id, HTTPMethod: method, parameters, parametersType, setRequest, Success: success, Failure: failure) else {
            return nil
        }
//        cancelRequest(path: path)
//        self.requestDictionary[path] = dataTask
        
        return dataTask
       
    }
    
    

    //MARK: - 上传数据 相关接口
    
    ///图片 上传
    ///
    /// - Parameters:
    ///   - urlStr: url
    ///   - method: 请求方法
    ///   - params: 请求参数（根据key来拼接（后续可能回接入用户名与token））
    ///   - data: 照片数据
    ///   - name: 需要与后台协商成统一字段
    ///   - fileNameArray: 文件名称，看后台有没有要求
    ///   - headers: header 可以没有
    ///   - mimeType: mimeType
    ///   - success: 成功
    ///   - failture: 失败 -- 如果没有数据，相当于失败。
    func uploadImage(_ urlStr : String,_ method: HTTPMethod, _ params:[String:String],_ images: [UIImage],_ names:String,_ fileNames:[String], _ headers: [String:String]?,_ compressionQuality: CGFloat? = 0.1 , _ mimeType: String ,success : @escaping (_ response : [String : AnyObject])->(), failture : @escaping (_ error : Error)->()) {
       
        if YKNetworkStatus.sharedInstance.isConnect == false {
           
            print(noNetString)
            return
        }
        self.uploadImageFunc(urlStr, method, params, images, names, fileNames, headers, compressionQuality, mimeType, success: success, failture: failture)
    }
    
    ///上传
    ///
    /// - Parameters:
    ///   - urlStr: url
    ///   - method: 请求方法
    ///   - params: 请求参数（根据key来拼接（后续可能回接入用户名与token））
    ///   - data: 照片数据
    ///   - name: 需要与后台协商成统一字段
    ///   - fileNameArray: 文件名称，看后台有没有要求
    ///   - headers: header 可以没有
    ///   - mimeType: mimeType
    ///   - success: 成功
    ///   - failture: 失败 -- 如果没有数据，相当于失败。
    func upload(_ urlStr : String,_ method: HTTPMethod, _ params:[String:String],_ data: [Data],_ names:[String],_ fileNames:[String], _ headers: [String:String]?,_ mimeType: String, success : @escaping (_ response : [String : AnyObject])->(), failture : @escaping (_ error : Error)->()) {
   
        if YKNetworkStatus.sharedInstance.isConnect == false {
         
            print(noNetString)
            return
        }
        self.uploadFunc(urlStr, method, params, data, names, fileNames, headers, mimeType, success: success, failture: failture)
    }
}





//MARK: - 下载数据 extension
private extension AlamofireMenager {
    /// alamofire 数据请求 （数据为object）
    ///注意循环引用
    /// - Parameters:
    ///   - path: url path
    ///   - method: 请求方式
    ///   - parameters: 参数
    ///   - parametersType: 参数为 query 还是 body
    ///   - responseDateType: 网络数据类型
    ///   - success: 成功的回调
    ///   - failure: 失败的回调
    /// - Returns: Request
    @discardableResult
    func loadDataObject<T:BaseMappable>(Path path: String,Id id: String , HTTPMethod method: HTTPMethod? = .get,_ parameters: [String:Any]? = nil,_ parametersType: ParamaetersType? = nil,_ setRequest: ((_ request: DataRequest) -> Void)? = nil,Success success: @escaping (T,_ response: DataResponse<T>) -> Void, Failure failure:@escaping(_ errorMsg:String) -> Void) -> (DataRequest?) {
   
        let httpMethod = HTTPMethod.init(rawValue: (method?.rawValue ?? "GET"))
        let dateRequest = RequestMenager.getDataRequest(Path: path, HTTPMethod: httpMethod, parameters, parametersType)
        guard let request = dateRequest else {
            return nil
        }
        
        setRequest?(request)
        if isShowLoading {
           SVProgressHUD.show()
        }
       
        request.responseObject(completionHandler: { [weak self] (netDate:DataResponse<T>) in
            if self == nil{
                dPrint("🌶网络请求工具 AlamofireMenager，被销毁请检查")
            }
            let isSuccess = k_codeMenager.handleCode(netDate.response?.statusCode ?? 0, netDate.result.value, netDate.error, netDate.request?.url)
            print(netDate)
            if isSuccess && netDate.result.value != nil {
                if isDebug {
                    let dataStr = netDate.result.value?.toJSONString(prettyPrint: true)
                    dPrint(dataStr ?? "")
                }
                success(netDate.result.value!,netDate)
                 SVProgressHUD.dismiss()
            }else{
                
                failure((self?.errorShowMassage) ?? "")
                
                  SVProgressHUD.showError(withStatus: (self?.errorShowMassage) ?? "")
            }
//             self?.cancelRequest(path: path)
            self?.requestDictionary.removeValue(forKey: id)
        })
        
        return request
    }
    /// alamofire 数据请求 (数据Json)
    ///注意循环引用
    /// - Parameters:
    ///   - path: url path
    ///   - method: 请求方式
    ///   - parameters: 参数
    ///   - parametersType: 参数为 query 还是 body
    ///   - responseDateType: 网络数据类型
    ///   - success: 成功的回调
    ///   - failure: 失败的回调
    /// - Returns: Request
    @discardableResult
    func loadDataJson(Path path: String,Id id:String, HTTPMethod method: HTTPMethod? = .get,_ parameters: [String:Any]? = nil,_ parametersType: ParamaetersType? = nil,_ setRequest: ((_ request: DataRequest) -> Void)? = nil,Success success: @escaping (_ json: Any, DataResponse<Any>) -> Void, Failure failure:@escaping(_ errorMsg:String) -> Void) -> (DataRequest?) {
        
        let httpMethod = HTTPMethod.init(rawValue: (method?.rawValue ?? "GET"))
        let dateRequest = RequestMenager.getDataRequest(Path: path, HTTPMethod: httpMethod, parameters, parametersType)
        guard let request = dateRequest else {
            return nil
        }
        
        setRequest?(request)
        if isShowLoading {
            SVProgressHUD.show()
        }
        request.responseJSON(completionHandler: { [weak self] (netDate:DataResponse<Any>) in
            if self == nil{
                dPrint("🌶网络请求工具 AlamofireMenager，被销毁请检查")
            }
            let isSuccess = k_codeMenager.handleCode(netDate.response?.statusCode ?? 0, netDate.result.value, netDate.error, netDate.request?.url)
            if isSuccess && netDate.result.value != nil {
                if isDebug {
                    dPrint(netDate.result.value ?? "没有数据")
                }
                success(netDate.result.value!,netDate)
                  SVProgressHUD.dismiss()
            }else{
                failure((self?.errorShowMassage) ?? "")
                if (self?.isShowLoading)! {
                  SVProgressHUD.showError(withStatus: (self?.errorShowMassage) ?? "")
                }
                
            }
//            self?.cancelRequest(path: path)
            self?.requestDictionary.removeValue(forKey: id)
        })
        return request
    }
    
    /// alamofire 数据请求 (数据数组)
    ///注意循环引用
    /// - Parameters:
    ///   - path: url path
    ///   - method: 请求方式
    ///   - parameters: 参数
    ///   - parametersType: 参数为 query 还是 body
    ///   - responseDateType: 网络数据类型
    ///   - success: 成功的回调
    ///   - failure: 失败的回调
    /// - Returns: Request
    @discardableResult
    func loadDataArray<T:BaseMappable>(Path path: String,Id id:String, HTTPMethod method: HTTPMethod? = .get,_ parameters: [String:Any]? = nil,_ parametersType: ParamaetersType? = nil,_ setRequest: ((_ request: DataRequest) -> Void)? = nil,Success success: @escaping ([T],DataResponse<[T]>) -> Void, Failure failure:@escaping(_ errorMsg:String) -> Void) -> (DataRequest?) {
        
        let httpMethod = HTTPMethod.init(rawValue: (method?.rawValue ?? "GET"))
        let dateRequest = RequestMenager.getDataRequest(Path: path, HTTPMethod: httpMethod, parameters, parametersType)
        guard let request = dateRequest else {
            return nil
        }
        
        setRequest?(request)
        if isShowLoading {
            SVProgressHUD.show()
        }
        request.responseArray(completionHandler: { [weak self] (netDate:DataResponse<[T]>) in
            if self == nil{
                dPrint("🌶网络请求工具 AlamofireMenager，被销毁请检查")
            }
            
            let isSuccess = k_codeMenager.handleCode(netDate.response?.statusCode ?? 0, netDate.result.value, netDate.error, netDate.request?.url)
            
            if isSuccess && netDate.result.value != nil {
                if isDebug {
                    let dataStr = netDate.result.value?.toJSONString(prettyPrint: true)
                    dPrint(dataStr ?? "")
                }
                success(netDate.result.value!,netDate)
                 SVProgressHUD.dismiss()
            }else{
                failure((self?.errorShowMassage) ?? "")
                  SVProgressHUD.showError(withStatus: (self?.errorShowMassage) ?? "")
            }
//            self?.cancelRequest(path: path)
            self?.requestDictionary.removeValue(forKey: id)
        })
        return request
    }
}


//MARK: - 上传数据 extension
private extension AlamofireMenager {
    
    ///图片 上传
    ///
    /// - Parameters:
    ///   - urlStr: url
    ///   - method: 请求方法
    ///   - params: 请求参数（根据key来拼接（后续可能回接入用户名与token））
    ///   - data: 照片数据
    ///   - name: 需要与后台协商成统一字段
    ///   - fileNameArray: 文件名称，看后台有没有要求
    ///   - headers: header 可以没有
    ///   - mimeType: mimeType
    ///   - success: 成功
    ///   - failture: 失败 -- 如果没有数据，相当于失败。
    func uploadImageFunc(_ urlStr : String,_ method: HTTPMethod, _ params:[String:String],_ images: [UIImage],_ name:String,_ fileNameArray:[String], _ headers: [String:String]?,_ compressionQuality: CGFloat? = 0.1 , _ mimeType: String ,success : @escaping (_ response : [String : AnyObject])->(), failture : @escaping (_ error : Error)->()) {
        var imageDataArray:[Data] = []
        var imageNameArray:[String] = []
        for i in 0..<images.count {
            let image = images[i]
            if let imageData = UIImageJPEGRepresentation(image, compressionQuality!) {
                imageDataArray.append(imageData)
                
                let imageName = String(describing: NSDate()) + "\(i).png"
                imageNameArray.append(imageName)
                continue
            }
            dPrint(image)
            dPrint("转化Data失败\n")
        }
        self.upload(urlStr, method, params, imageDataArray, imageNameArray, fileNameArray, headers, mimeType, success: success,failture: failture)
    }
    
    
    ///上传
    ///
    /// - Parameters:
    ///   - urlStr: url
    ///   - method: 请求方法
    ///   - params: 请求参数（根据key来拼接（后续可能回接入用户名与token））
    ///   - data: 照片数据
    ///   - name: 需要与后台协商成统一字段
    ///   - fileNameArray: 文件名称，看后台有没有要求
    ///   - headers: header 可以没有
    ///   - mimeType: mimeType
    ///   - success: 成功
    ///   - failture: 失败 -- 如果没有数据，相当于失败。
    func uploadFunc(_ path : String,_ method: HTTPMethod, _ params:[String:String],_ data: [Data],_ names:[String],_ fileNames:[String], _ headers: [String:String]?,_ mimeType: String, success : @escaping (_ response : [String : AnyObject])->(), failture : @escaping (_ error : Error)->()) {
        //header的上传
        let headers = headers ?? ["content-type":"multipart/form-data"]
        
        ///url 拼接
        let requstOption = RequestMenager.getURLRequest(Path: path, HTTPMethod: method, headers, ParamaetersType.query)
        
        guard let requst = requstOption else {
            dPrint("🌶\n 数据上传 request 转化失败 " + path + "🌶\n")
            return
        }
        AlamofireSession.default.sessionMenager.upload(multipartFormData: { multipartFormData in
            for (value,key) in params {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            for i in 0 ..< data.count {
                multipartFormData.append(data[i], withName: names[i], fileName: fileNames[i], mimeType: mimeType)
            }
        }, with: requst) { encodingResult in
            switch encodingResult {
            case .success(let request, let streamingFromDisk, let streamFileURL):
                dPrint(streamFileURL ?? "")
                dPrint(streamingFromDisk)
                request.responseJSON(completionHandler: { (netDate) in
                    let isSuccess = k_codeMenager.handleCode(netDate.response?.statusCode ?? 0, netDate.result.value, netDate.error, netDate.request?.url)
                    if isSuccess && netDate.result.value != nil {
                        if let value = netDate.result.value as? [String : AnyObject] {
                            success(value)
                        }else{
                            failture(netDate.error!)
                        }
                    }else{
                        failture(netDate.error!)
                    }
                })
            case .failure(let error):
                failture(error)
            }
        }
    }
}


