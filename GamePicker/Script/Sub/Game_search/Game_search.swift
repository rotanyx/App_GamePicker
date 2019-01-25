import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher

class Game_search: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    @IBOutlet var search_table: UITableView!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var search_bar: UISearchBar!
    @IBOutlet var state: UILabel!

    // 모든 게임을 저장할 배열
    lazy var all_game : [Game_VO] = {
        var datalist = [Game_VO]()
        return datalist
    }()
    
    // 저장된 게임을 저장할 배열
    lazy var searched_game : [Game_VO] = {
        var datalist = [Game_VO]()
        return datalist
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.startAnimating()
        search_bar.isHidden = true
        state.isHidden      = true
        get_games()
    }

    // 모든 게임 GET
    func get_games() {
        Alamofire.request(Api.url + "games").responseJSON { (response) in
            if response.result.isSuccess {
                let json = JSON(response.result.value!)
                if response.response?.statusCode == 200 {
                    for (_,subJson):(String, JSON) in json["games"] {
                        let gme = Game_VO()
                        gme.id        = subJson["id"].intValue
                        gme.title     = subJson["title"].stringValue
                        gme.thumbnail = subJson["images"][0].stringValue
                        
                        self.all_game.append(gme)
                    }
                    self.searched_game = self.all_game
                } else {
                    self.showalert(message: "서버 오류", can: 0)
                }
            } else {
                self.showalert(message: "서버 응답 오류", can: 0)
            }
            self.state.isHidden = false
            self.search_bar.isHidden = false
            self.indicator.stopAnimating()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searched_game.count == 0 {
            tableView.isHidden = true
            if search_bar.text!.isEmpty {
                state.text = "검색어를 입력하세요"
            } else {
                state.text = "\"\(search_bar.text ?? "")\"(은)는 없습니다"
            }
        } else {
            tableView.isHidden = false
        }
        return searched_game.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "game_search_cell") as! Game_search_cell
        let row = self.searched_game[indexPath.row]
        cell.game_title?.text = row.title
        cell.game_image.kf.indicatorType = .activity
        cell.game_image.kf.setImage(
            with: URL(string: row.thumbnail!),
            options: [
                .processor(DownsamplingImageProcessor(size: CGSize(width: 150, height: 100))),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.3)),
            ])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = self.searched_game[indexPath.row]
        let game_id : Int = row.id ?? 0
        self.performSegue(withIdentifier: "game_info", sender: game_id)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let param = segue.destination as! Game_info
        param.game_id = sender as! Int
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searched_game = all_game.filter({ game -> Bool in
            if search_bar.text!.isEmpty {
                return false
            } else {
                if let game_title = game.title {
                    return game_title.lowercased().contains(search_bar.text!.lowercased())
                }
            }
            return false
        })
        search_table.reloadData()
    }
    
}
